import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/services/auth_service.dart';
import '../../../../core/services/auth_service_firebase.dart';
import 'auth_state.dart';

final authControllerProvider =
    StateNotifierProvider<AuthController, AuthUIState>((ref) {
  return AuthController();
});

class AuthController extends StateNotifier<AuthUIState> {
  AuthController() : super(const AuthUIState());

  void clearError() {
    if (state.errorMessage != null) {
      state = state.copyWith(errorMessage: null);
    }
  }

  /// Cek apakah email sudah terdaftar di Firebase Auth
  Future<bool> checkEmailExists(String email) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      await FirebaseAuthService.signInWithEmail(email, '___spendly_check___');
      state = state.copyWith(status: AuthStatus.initial);
      return true;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        state = state.copyWith(status: AuthStatus.initial);
        return false;
      }
      if (e.code == 'wrong-password' ||
          e.code == 'invalid-credential' ||
          e.code == 'invalid-login-credentials') {
        state = state.copyWith(status: AuthStatus.initial);
        return true;
      }
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: getFriendlyErrorMessage(e.code),
      );
      return false;
    } catch (_) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: 'Terjadi kesalahan. Periksa koneksi internet.',
      );
      return false;
    }
  }

  /// Sign in dengan Email & Password
  Future<bool> signInWithEmail(String email, String password) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      final user = await FirebaseAuthService.signInWithEmail(email, password);
      if (user != null) {
        state = state.copyWith(status: AuthStatus.authenticated);
        return true;
      }
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: 'Gagal masuk. Silakan coba lagi.',
      );
      return false;
    } on FirebaseAuthException catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: getFriendlyErrorMessage(e.code),
      );
      return false;
    } catch (_) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: 'Terjadi kesalahan. Coba lagi.',
      );
      return false;
    }
  }

  /// Register dengan Email & Password
  Future<bool> registerWithEmail(String email, String password) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      final user = await FirebaseAuthService.registerWithEmail(email, password);
      if (user != null) {
        state = state.copyWith(status: AuthStatus.authenticated);
        return true;
      }
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: 'Gagal mendaftar. Silakan coba lagi.',
      );
      return false;
    } on FirebaseAuthException catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: getFriendlyErrorMessage(e.code),
      );
      return false;
    } catch (_) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: 'Terjadi kesalahan. Coba lagi.',
      );
      return false;
    }
  }

  /// Kirim email reset password
  Future<bool> sendPasswordReset(String email) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      await FirebaseAuthService.sendPasswordResetEmail(email);
      state = state.copyWith(status: AuthStatus.initial);
      return true;
    } on FirebaseAuthException catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: getFriendlyErrorMessage(e.code),
      );
      return false;
    } catch (_) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: 'Gagal mengirim email reset password.',
      );
      return false;
    }
  }

  /// Sign Out / Logout
  Future<void> signOut() async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      await AuthService.clearAllOnLogout();
      await FirebaseAuthService.signOut();
      state = state.copyWith(status: AuthStatus.unauthenticated);
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: 'Gagal keluar: $e',
      );
    }
  }

  /// Pemetaan kode error Firebase Auth ke pesan Bahasa Indonesia yang ramah
  static String getFriendlyErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'Akun tidak ditemukan';
      case 'wrong-password':
      case 'invalid-credential':
      case 'invalid-login-credentials':
        return 'Password salah. Silakan coba lagi.';
      case 'email-already-in-use':
        return 'Email sudah terdaftar. Silakan login.';
      case 'invalid-email':
        return 'Format email tidak valid';
      case 'weak-password':
        return 'Password terlalu lemah (minimal 6 karakter)';
      case 'too-many-requests':
        return 'Terlalu banyak percobaan. Coba lagi nanti.';
      case 'network-request-failed':
        return 'Koneksi terputus. Periksa jaringan Anda.';
      default:
        return 'Terjadi kesalahan ($code)';
    }
  }
}
