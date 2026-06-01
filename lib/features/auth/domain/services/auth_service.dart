import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// AuthService — PIN management
///
/// ATURAN WAJIB:
/// • PIN HANYA disimpan di local secure storage
/// • PIN TIDAK pernah dikirim ke Firebase
/// • PIN WAJIB dihapus saat logout via clearAllOnLogout()
///
class AuthService {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  static String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  static String _pinKey(String uid)        => '${uid}_pin';
  static String _pinDecidedKey(String uid) => '${uid}_pin_decided';

  // ─── PIN ──────────────────────────────────────────────────────────────────

  static Future<bool> isPinEnabled() async {
    final uid = _uid;
    if (uid == null) return false;
    final pin = await _storage.read(key: _pinKey(uid));
    return pin != null && pin.isNotEmpty;
  }

  static Future<void> setPin(String pin) async {
    final uid = _uid;
    if (uid == null) throw StateError('AuthService: no authenticated user');
    await _storage.write(key: _pinKey(uid), value: pin);
    await markPinDecisionMade();
  }

  static Future<bool> verifyPin(String pin) async {
    final uid = _uid;
    if (uid == null) return false;
    final stored = await _storage.read(key: _pinKey(uid));
    return stored != null && stored == pin;
  }

  static Future<void> disablePin() async {
    final uid = _uid;
    if (uid == null) return;
    await _storage.delete(key: _pinKey(uid));
    await markPinDecisionMade();
  }

  // ─── PIN Setup Decision ───────────────────────────────────────────────────
  //
  // Digunakan untuk membedakan antara:
  //   • User baru (belum pernah diputuskan) → tampilkan setup PIN
  //   • User yang sudah memilih skip        → jangan tampilkan lagi
  //
  // Reset saat logout agar user harus membuat PIN baru di login berikutnya.

  static Future<bool> hasPinDecisionBeenMade() async {
    final uid = _uid;
    if (uid == null) return false;
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_pinDecidedKey(uid)) ?? false;
  }

  static Future<void> markPinDecisionMade() async {
    final uid = _uid;
    if (uid == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_pinDecidedKey(uid), true);
  }

  // ─── LOGOUT — WAJIB dipanggil sebelum FirebaseAuth.signOut() ─────────────
  //
  // Urutan logout yang benar:
  //   1. await AuthService.clearAllOnLogout()   ← hapus PIN dari device
  //   2. await FirebaseAuthService.signOut()    ← hapus sesi Firebase
  //
  // JANGAN tukar urutannya karena clearAllOnLogout()
  // membutuhkan currentUser?.uid yang masih valid.

  static Future<void> clearAllOnLogout() async {
    final uid = _uid;
    if (uid == null) return;
    await _storage.delete(key: _pinKey(uid));
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_pinDecidedKey(uid));
  }
}