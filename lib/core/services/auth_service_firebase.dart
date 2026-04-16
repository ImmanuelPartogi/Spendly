import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

// ─────────────────────────────────────────────────────────────────────────────
// FirebaseAuthService
//
// Strategi:
// - Jika user belum login → login anonymous (data tetap tersimpan di Firebase)
// - Jika user mau link ke akun email → bisa upgrade anonymous ke email
// - Saat offline → Firebase Auth menyimpan state lokal, tidak perlu login ulang
// ─────────────────────────────────────────────────────────────────────────────

class FirebaseAuthService {
  static final _auth = FirebaseAuth.instance;

  /// User ID yang aktif (anonymous atau email)
  static String? get currentUserId => _auth.currentUser?.uid;

  /// Apakah sudah ada user yang login
  static bool get isLoggedIn => _auth.currentUser != null;

  /// Login anonymous — dipanggil otomatis saat app start
  /// Data tetap tersimpan di Firestore dengan UID anonymous
  static Future<String> signInAnonymously() async {
    try {
      if (_auth.currentUser != null) {
        return _auth.currentUser!.uid;
      }
      final credential = await _auth.signInAnonymously();
      debugPrint('[Auth] Signed in anonymous: ${credential.user?.uid}');
      return credential.user!.uid;
    } catch (e) {
      debugPrint('[Auth] Anonymous sign-in failed: $e');
      // Fallback ke device ID jika Firebase tidak tersedia
      return 'local_user';
    }
  }

  /// Login dengan email & password
  static Future<User?> signInWithEmail(
      String email, String password) async {
    print('🔐 Mencoba login: $email');
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      // Jika sebelumnya anonymous, data anonymous tetap ada di Firestore
      // (tidak otomatis merge — perlu SyncService.mergeAnonymousData)
      print('✅ Login berhasil! UID: ${credential.user?.uid}');
      debugPrint('[Auth] Signed in: ${credential.user?.uid}');
      return credential.user;
    } on FirebaseAuthException catch (e) {
      print('❌ Login gagal: ${e.code} - ${e.message}');
      debugPrint('[Auth] Sign-in error: ${e.code} - ${e.message}');
      rethrow;
    }
  }

  /// Register email & password baru
  static Future<User?> registerWithEmail(
      String email, String password) async {
    try {
      final credential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return credential.user;
    } on FirebaseAuthException catch (e) {
      debugPrint('[Auth] Register error: ${e.code} - ${e.message}');
      rethrow;
    }
  }

  /// Upgrade anonymous → email (data anonymous ter-merge otomatis)
  static Future<User?> upgradeAnonymousToEmail(
      String email, String password) async {
    try {
      final user = _auth.currentUser;
      if (user == null || !user.isAnonymous) return null;

      final credential = EmailAuthProvider.credential(
          email: email, password: password);
      final result = await user.linkWithCredential(credential);
      debugPrint('[Auth] Upgraded to email: ${result.user?.uid}');
      return result.user;
    } on FirebaseAuthException catch (e) {
      debugPrint('[Auth] Upgrade error: ${e.code}');
      rethrow;
    }
  }

  /// Logout
  static Future<void> signOut() async {
    await _auth.signOut();
  }

  /// Stream perubahan auth state
  static Stream<User?> get authStateChanges =>
      _auth.authStateChanges();

  /// Cek apakah user anonymous
  static bool get isAnonymous =>
      _auth.currentUser?.isAnonymous ?? true;
}