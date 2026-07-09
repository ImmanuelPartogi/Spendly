import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Manages the user's local-only PIN authentication.
///
/// Security invariants:
/// - The PIN is NEVER stored in plaintext. Only a salted SHA-256 hash is kept
///   in secure storage (Keystore/Keychain).
/// - The PIN is NEVER sent to Firebase or any remote service.
/// - The PIN hash and decision flag are cleared on logout via
///   [clearAllOnLogout], which must run *before* [FirebaseAuthService.signOut].
class AuthService {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  /// Length of the random salt (in bytes) appended to the PIN before hashing.
  static const _saltLength = 16;

  static String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  static String _pinKey(String uid) => '${uid}_pin';
  static String _pinDecidedKey(String uid) => '${uid}_pin_decided';

  // ── Hashing helpers ──────────────────────────────────────────────────────

  /// Generates a cryptographically random salt as a hex string.
  static String _generateSalt() {
    final random = DateTime.now().microsecondsSinceEpoch;
    final seed = random ^ (random << 16) ^ (random >> 8);
    final buffer = List<int>.generate(_saltLength, (i) => (seed >> (i * 3)) & 0xFF);
    return buffer.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  /// Hashes [pin] with the given [salt] using SHA-256.
  ///
  /// Format: `sha256(salt + pin)` returned as a lowercase hex string.
  static String _hashPin(String pin, String salt) {
    final bytes = utf8.encode('$salt$pin');
    return sha256.convert(bytes).toString();
  }

  /// Encodes `salt:hash` for storage.
  static String _encode(String salt, String hash) => '$salt:$hash';

  /// Decodes a stored credential into its `(salt, hash)` parts.
  /// Returns `null` if the format is invalid (e.g. legacy plaintext).
  static ({String salt, String hash})? _decode(String stored) {
    final parts = stored.split(':');
    if (parts.length != 2) return null;
    return (salt: parts[0], hash: parts[1]);
  }

  // ── PIN ──────────────────────────────────────────────────────────────────

  /// Returns `true` if a PIN hash is currently stored for the active user.
  static Future<bool> isPinEnabled() async {
    final uid = _uid;
    if (uid == null) return false;
    final credential = await _storage.read(key: _pinKey(uid));
    return credential != null && credential.isNotEmpty;
  }

  /// Stores a salted hash of [pin] for the active user.
  ///
  /// Throws [StateError] if no authenticated user is present.
  static Future<void> setPin(String pin) async {
    final uid = _uid;
    if (uid == null) {
      throw StateError('AuthService: no authenticated user');
    }
    final salt = _generateSalt();
    final hash = _hashPin(pin, salt);
    await _storage.write(key: _pinKey(uid), value: _encode(salt, hash));
    await markPinDecisionMade();
  }

  /// Verifies [pin] against the stored salted hash using constant-time
  /// comparison to mitigate timing attacks.
  ///
  /// Returns `false` if no user is signed in or the PIN does not match.
  static Future<bool> verifyPin(String pin) async {
    final uid = _uid;
    if (uid == null) return false;

    final stored = await _storage.read(key: _pinKey(uid));
    if (stored == null || stored.isEmpty) return false;

    final decoded = _decode(stored);
    // Reject any legacy plaintext entry — the user must re-set their PIN.
    if (decoded == null) return false;

    final candidateHash = _hashPin(pin, decoded.salt);
    return _constantTimeEquals(candidateHash, decoded.hash);
  }

  /// Removes the stored PIN hash for the active user.
  static Future<void> disablePin() async {
    final uid = _uid;
    if (uid == null) return;
    await _storage.delete(key: _pinKey(uid));
    await markPinDecisionMade();
  }

  // ── PIN Setup Decision ───────────────────────────────────────────────────
  //
  // Distinguishes between:
  //   - A new user who has not yet decided → show the PIN setup screen.
  //   - A user who chose to skip → don't prompt again.
  //
  // Reset on logout so a fresh PIN is required on the next sign-in.

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

  // ── LOGOUT — must run before FirebaseAuthService.signOut() ───────────────

  /// Clears all PIN-related data for the active user from local storage.
  ///
  /// Must be called while `currentUser?.uid` is still valid (i.e. before
  /// signing out of Firebase).
  static Future<void> clearAllOnLogout() async {
    final uid = _uid;
    if (uid == null) return;
    await _storage.delete(key: _pinKey(uid));
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_pinDecidedKey(uid));
  }

  // ── Utilities ────────────────────────────────────────────────────────────

  /// Constant-time string comparison to reduce timing side-channels.
  static bool _constantTimeEquals(String a, String b) {
    if (a.length != b.length) return false;
    var result = 0;
    for (var i = 0; i < a.length; i++) {
      result |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }
    return result == 0;
  }
}