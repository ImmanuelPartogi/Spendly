import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:local_auth/local_auth.dart';
import 'package:spendly/core/services/sync_service.dart';

/// AuthService — manajemen PIN, biometric, dan credential cache
///
/// Sumber kebenaran PIN : Firebase (users/{uid}.pin + pinEnabled)
///                        pin_lookup/{email} — untuk lookup sebelum login
/// Cache lokal          : SharedPreferences — dipakai saat offline / setelah restore
/// Credential cache     : FlutterSecureStorage — untuk sign-in via PIN di device baru
///
/// Alur login via PIN (device sudah pernah login):
///   1. User masukkan email → SyncService.checkPinByEmail() → pinEnabled: true
///   2. User masukkan PIN   → hashPin() dibandingkan dengan pinHash di Firestore
///   3. PIN benar           → getCachedCredentials() → Firebase sign-in otomatis
///   4. Tidak ada cache     → fallback ke password
///
/// Alur setPin():
///   - Simpan PIN ke cache lokal (SharedPreferences)
///   - Upload PIN ke users/{uid} di Firebase
///   - Upload pinHash ke pin_lookup/{email} untuk lookup pra-login
///
class AuthService {
  static const _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  // ─── UID helper ───────────────────────────────────────────────────────────
  //
  // Kembalikan uid yang sedang login, atau null jika belum ada user.
  // Jangan pernah fallback ke 'local' — key SharedPreferences yang salah
  // menyebabkan data bocor antar-akun atau tidak terbaca setelah restore.
  //
  static String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  /// Kembalikan uid, throw [StateError] jika user belum login.
  /// Dipakai di method yang *harus* ada user aktif (setPin, disablePin, dst).
  static String _requireUid() {
    final uid = _uid;
    if (uid == null) throw StateError('AuthService: no authenticated user');
    return uid;
  }

  // ─── Cache key helpers (eksplisit per-uid) ────────────────────────────────

  static String _pinCacheKey(String uid)       => '${uid}_pin_cache';
  static String _pinEnabledCacheKey(String uid) => '${uid}_pin_enabled_cache';
  static String _biometricKey(String uid)       => '${uid}_biometric_enabled';

  static const String _pinSetupPendingKey = 'pin_setup_pending';
  static const String _credEmailKey       = 'spendly_cached_email';
  static const String _credPasswordKey    = 'spendly_cached_password';

  // ─── PIN Hash (public — dipakai di LoginScreen) ───────────────────────────
  //
  // Format: sha256(pin + ":" + email.toLowerCase())
  // Disimpan di pin_lookup Firestore agar bisa diverifikasi sebelum Firebase Auth.
  //
  static String hashPin(String pin, String email) {
    final input = '$pin:${email.toLowerCase().trim()}';
    final bytes = utf8.encode(input);
    return sha256.convert(bytes).toString();
  }

  // ─── Credential Cache (FlutterSecureStorage) ──────────────────────────────
  //
  // Disimpan saat user berhasil login dengan password.
  // Dipakai untuk Firebase Auth otomatis saat user login via PIN.
  //

  static Future<void> cacheCredentials(String email, String password) async {
    await _secureStorage.write(key: _credEmailKey, value: email);
    await _secureStorage.write(key: _credPasswordKey, value: password);
  }

  static Future<({String email, String password})?> getCachedCredentials() async {
    final email    = await _secureStorage.read(key: _credEmailKey);
    final password = await _secureStorage.read(key: _credPasswordKey);
    if (email == null || password == null) return null;
    return (email: email, password: password);
  }

  static Future<void> clearCachedCredentials() async {
    await _secureStorage.delete(key: _credEmailKey);
    await _secureStorage.delete(key: _credPasswordKey);
  }

  // ─── PIN: read dari cache lokal ───────────────────────────────────────────
  //
  // Kembalikan false (bukan throw) jika user belum login — caller cukup
  // tahu bahwa PIN tidak tersedia, tidak perlu crash.
  //
  static Future<bool> isPinEnabled() async {
    final uid = _uid;
    if (uid == null) return false;

    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_pinEnabledCacheKey(uid)) ?? false;
  }

  // ─── PIN: set — simpan lokal + upload Firebase + update pin_lookup ────────

  static Future<void> setPin(String pin) async {
    final uid   = _requireUid(); // throw jika belum login
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(_pinCacheKey(uid), pin);
    await prefs.setBool(_pinEnabledCacheKey(uid), true);

    // Upload ke users/{uid} — sumber kebenaran utama
    await SyncService.uploadPin(pin: pin, enabled: true);

    // Update pin_lookup/{email} — untuk lookup pra-login tanpa auth
    final email = FirebaseAuth.instance.currentUser?.email ?? '';
    if (email.isNotEmpty) {
      final pinHash = hashPin(pin, email);
      await SyncService.uploadPinLookup(
        email:   email,
        enabled: true,
        pinHash: pinHash,
      );
    }
  }

  // ─── PIN: verify dari cache lokal ─────────────────────────────────────────

  static Future<bool> verifyPin(String pin) async {
    final uid = _uid;
    if (uid == null) return false;

    final prefs  = await SharedPreferences.getInstance();
    final cached = prefs.getString(_pinCacheKey(uid));
    return cached != null && cached == pin;
  }

  // ─── PIN: disable ─────────────────────────────────────────────────────────

  static Future<void> disablePin() async {
    final uid   = _requireUid();
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove(_pinCacheKey(uid));
    await prefs.setBool(_pinEnabledCacheKey(uid), false);

    await SyncService.disablePin();

    // Hapus pin_lookup entry agar login berikutnya pakai password
    final email = FirebaseAuth.instance.currentUser?.email ?? '';
    if (email.isNotEmpty) {
      await SyncService.uploadPinLookup(
        email:   email,
        enabled: false,
        pinHash: '',
      );
    }
  }

  // ─── PIN: restore dari Firebase ke cache lokal ────────────────────────────
  //
  // Dipanggil setelah Firebase sign-in berhasil, saat SyncService menarik
  // data user dari Firestore. uid *harus* sudah tersedia di titik ini.
  //
  static Future<bool> restorePin(Map<String, dynamic> pinData) async {
    // Guard: jangan write ke key 'local_pin_cache' jika uid belum ada
    final uid = _uid;
    if (uid == null) return false;

    final pin     = pinData['pin'] as String?;
    final enabled = pinData['pinEnabled'] as bool? ?? false;
    final prefs   = await SharedPreferences.getInstance();

    if (pin != null && enabled) {
      await prefs.setString(_pinCacheKey(uid), pin);
      await prefs.setBool(_pinEnabledCacheKey(uid), true);

      // Pastikan pin_lookup tersinkron setelah restore
      final email = FirebaseAuth.instance.currentUser?.email ?? '';
      if (email.isNotEmpty) {
        final pinHash = hashPin(pin, email);
        await SyncService.uploadPinLookup(
          email:   email,
          enabled: true,
          pinHash: pinHash,
        );
      }
      return true;
    } else {
      await prefs.remove(_pinCacheKey(uid));
      await prefs.setBool(_pinEnabledCacheKey(uid), false);
      return false;
    }
  }

  // ─── PIN setup pending ────────────────────────────────────────────────────
  //
  // Key ini sengaja tidak di-prefix uid karena statusnya bersifat
  // sementara (in-flight setup) dan tidak terkait data per-akun.
  //

  static Future<void> setPinSetupPending(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value) {
      await prefs.setBool(_pinSetupPendingKey, true);
    } else {
      await prefs.remove(_pinSetupPendingKey);
    }
  }

  static Future<bool> isPinSetupPending() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_pinSetupPendingKey) ?? false;
  }

  // ─── Biometric ────────────────────────────────────────────────────────────

  static Future<bool> isBiometricEnabled() async {
    final uid = _uid;
    if (uid == null) return false;

    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_biometricKey(uid)) ?? false;
  }

  static Future<bool> isBiometricAvailable() async {
    final localAuth = LocalAuthentication();
    try {
      return await localAuth.canCheckBiometrics;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> authenticateBiometric() async {
    final localAuth = LocalAuthentication();
    try {
      return await localAuth.authenticate(
        localizedReason: 'Authenticate to access Spendly',
        options: const AuthenticationOptions(
          biometricOnly: true,
          useErrorDialogs: true,
        ),
      );
    } catch (_) {
      return false;
    }
  }

  static Future<void> setBiometricEnabled(bool enabled) async {
    final uid = _requireUid();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_biometricKey(uid), enabled);
  }
}