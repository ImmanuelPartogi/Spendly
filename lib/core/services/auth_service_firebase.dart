import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class FirebaseAuthService {
  static final _auth = FirebaseAuth.instance;

  static String? get currentUserId => _auth.currentUser?.uid;
  static bool get isLoggedIn => _auth.currentUser != null;

  static Future<String> signInAnonymously() async {
    try {
      if (_auth.currentUser != null) return _auth.currentUser!.uid;
      final credential = await _auth.signInAnonymously();
      debugPrint('[Auth] Signed in anonymous: ${credential.user?.uid}');
      return credential.user!.uid;
    } catch (e) {
      debugPrint('[Auth] Anonymous sign-in failed: $e');
      return 'local_user';
    }
  }

  static Future<User?> signInWithEmail(String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      debugPrint('[Auth] Signed in: ${credential.user?.uid}');
      return credential.user;
    } on FirebaseAuthException catch (e) {
      debugPrint('[Auth] Sign-in error: ${e.code} - ${e.message}');
      rethrow;
    }
  }

  static Future<User?> registerWithEmail(String email, String password) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return credential.user;
    } on FirebaseAuthException catch (e) {
      debugPrint('[Auth] Register error: ${e.code} - ${e.message}');
      rethrow;
    }
  }

  static Future<User?> upgradeAnonymousToEmail(
      String email, String password) async {
    try {
      final user = _auth.currentUser;
      if (user == null || !user.isAnonymous) return null;
      final credential =
          EmailAuthProvider.credential(email: email, password: password);
      final result = await user.linkWithCredential(credential);
      debugPrint('[Auth] Upgraded to email: ${result.user?.uid}');
      return result.user;
    } on FirebaseAuthException catch (e) {
      debugPrint('[Auth] Upgrade error: ${e.code}');
      rethrow;
    }
  }

  static Future<void> signOut() async => await _auth.signOut();

  static Stream<User?> get authStateChanges => _auth.authStateChanges();

  static bool get isAnonymous => _auth.currentUser?.isAnonymous ?? true;

  /// Update Firebase Auth password — panggil setelah setPin()
  static Future<void> updatePassword(String newPassword) async {
    await _auth.currentUser!.updatePassword(newPassword);
  }

  /// Reauthenticate dengan email + password — diperlukan sebelum updatePassword
  /// jika sesi sudah tidak fresh (requires-recent-login)
  static Future<void> reauthenticate(String email, String password) async {
    final credential =
        EmailAuthProvider.credential(email: email, password: password);
    await _auth.currentUser!.reauthenticateWithCredential(credential);
  }
}