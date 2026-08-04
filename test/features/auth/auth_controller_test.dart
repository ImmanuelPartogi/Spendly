import 'package:flutter_test/flutter_test.dart';
import 'package:spendly/features/auth/presentation/controllers/auth_controller.dart';
import 'package:spendly/features/auth/presentation/controllers/auth_state.dart';

void main() {
  group('AuthUIState Unit Tests', () {
    test('initial state has AuthStatus.initial and null error', () {
      const state = AuthUIState();
      expect(state.status, AuthStatus.initial);
      expect(state.errorMessage, isNull);
      expect(state.isLoading, isFalse);
    });

    test('copyWith updates status and error correctly', () {
      const state = AuthUIState();
      final loading = state.copyWith(status: AuthStatus.loading);
      expect(loading.status, AuthStatus.loading);
      expect(loading.isLoading, isTrue);

      final error = state.copyWith(
        status: AuthStatus.error,
        errorMessage: 'Salah password',
      );
      expect(error.status, AuthStatus.error);
      expect(error.errorMessage, 'Salah password');
    });

    test('getFriendlyErrorMessage maps codes to Indonesian text', () {
      expect(
        AuthController.getFriendlyErrorMessage('user-not-found'),
        'Akun tidak ditemukan',
      );
      expect(
        AuthController.getFriendlyErrorMessage('wrong-password'),
        'Password salah. Silakan coba lagi.',
      );
      expect(
        AuthController.getFriendlyErrorMessage('email-already-in-use'),
        'Email sudah terdaftar. Silakan login.',
      );
      expect(
        AuthController.getFriendlyErrorMessage('unknown_code'),
        'Terjadi kesalahan (unknown_code)',
      );
    });
  });
}
