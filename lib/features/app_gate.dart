import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spendly/features/auth/domain/services/auth_service.dart';
import 'package:spendly/features/auth/presentation/screens/login_screen.dart';
import 'package:spendly/features/auth/presentation/screens/pin_screen.dart';
import 'package:spendly/features/onboarding/presentation/screens/onboarding_screen.dart';
import 'package:spendly/core/navigation/main_navigation.dart';
import 'package:spendly/core/providers.dart';
import 'package:spendly/core/theme/app_colors.dart';
import 'package:spendly/core/auth/auth_provider.dart';
import 'package:spendly/core/services/auth_service_firebase.dart';

class AppGate extends ConsumerStatefulWidget {
  const AppGate({super.key});

  @override
  ConsumerState<AppGate> createState() => _AppGateState();
}

class _AppGateState extends ConsumerState<AppGate> {
  bool? _onboardingDone;
  bool _pinEnabled = false;
  bool _pinLocked = false;
  bool _pinSetupPending = false;
  bool _checkingPrefs = true;

  // true setelah user pilih "Lupa PIN" → login via password
  // Mencegah PinScreen muncul lagi di sesi yang sama setelah re-login
  bool _bypassPinThisSession = false;

  String? _lastUserId;

  @override
  @override
  void initState() {
    super.initState();
    _loadInitialPrefs();
  }

  Future<void> _loadInitialPrefs() async {
    final onboarding = await isOnboardingDone();
    if (mounted) {
      setState(() {
        _onboardingDone = onboarding;
        _checkingPrefs = false;
        // Tidak set _pinEnabled/_pinLocked di sini —
        // biarkan _reloadForNewUser yang handle setelah restore selesai
      });
    }
  }

  // ─── Ganti akun ───────────────────────────────────────────────────────────
  //
  // Dipanggil setiap kali uid berubah.
  // PIN sudah di-restore ke cache lokal oleh RestoreService.restoreFromFirebase()
  // sebelum fungsi ini berjalan (via main.dart authStateChanges listener).
  // Kita cukup membaca ulang dari cache lokal.
  //
  Future<void> _reloadForNewUser(User user) async {
    if (_lastUserId == user.uid) return;
    _lastUserId = user.uid;

    // Invalidate FutureProvider — StreamProvider Drift auto-update setelah DB berubah
    ref
      ..invalidate(bottomNavIndexProvider)
      ..invalidate(selectedMonthProvider)
      ..invalidate(analyticsPeriodProvider)
      ..invalidate(analyticsCustomRangeProvider)
      ..invalidate(insightsProvider)
      ..invalidate(monthlySpendingProvider);

    // Baca status PIN dari cache lokal (sudah diisi oleh RestoreService)
    final pin = await AuthService.isPinEnabled();
    final pinPending = await AuthService.isPinSetupPending();

    if (mounted) {
      setState(() {
        _pinEnabled = pin;
        _pinLocked = pin && !_bypassPinThisSession;
        _pinSetupPending = pinPending;
        _bypassPinThisSession = false;
      });
    }
  }

  // ─── PIN handlers ─────────────────────────────────────────────────────────

  void _onPinVerifySuccess() {
    if (mounted) setState(() => _pinLocked = false);
  }

  Future<void> _onPinSetupSuccess() async {
    await AuthService.setPinSetupPending(false);
    final pin = await AuthService.isPinEnabled();
    if (mounted) {
      setState(() {
        _pinSetupPending = false;
        _pinEnabled = pin;
        _pinLocked = false;
      });
    }
  }

  Future<void> _onPinSetupSkip() async {
    await AuthService.setPinSetupPending(false);
    if (mounted) setState(() => _pinSetupPending = false);
  }

  // ─── "Lupa PIN" → password sebagai fallback ───────────────────────────────
  //
  // Flow:
  //   1. Set _bypassPinThisSession = true
  //   2. Sign out → authStateProvider emit null → tampilkan LoginScreen
  //   3. User login dengan email/password
  //   4. authStateProvider emit User → _reloadForNewUser() dipanggil
  //   5. _bypassPinThisSession = true → _pinLocked = false → langsung Dashboard
  //
  Future<void> _onForgotPin() async {
    if (mounted) setState(() => _bypassPinThisSession = true);
    await FirebaseAuthService.signOut();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final restoreReady = ref.watch(restoreReadyProvider);

    return authState.when(
      loading: () => const _SplashView(),
      error: (_, __) => const LoginScreen(),
      data: (user) {
        if (_checkingPrefs || _onboardingDone == null)
          return const _SplashView();

        // ── Onboarding ────────────────────────────────────────────────────
        if (!_onboardingDone!) {
          return OnboardingScreen(
            onDone: () async {
              await markOnboardingDone();
              if (mounted) setState(() => _onboardingDone = true);
            },
          );
        }

        // ── Belum login ───────────────────────────────────────────────────
        if (user == null) {
          // reset state saat logout
          if (_lastUserId != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted)
                setState(() {
                  _lastUserId = null;
                  _pinLocked = _pinEnabled && !_bypassPinThisSession;
                });
            });
          }
          return const LoginScreen();
        }

        // Tampilkan splash selama restore berlangsung
        if (!restoreReady) return const _SplashView();

        if (_lastUserId != user.uid) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _reloadForNewUser(user);
          });
          return const _SplashView();
        }

        // ── PIN verify — akses utama ───────────────────────────────────────
        if (_pinEnabled && _pinLocked) {
          return PinScreen(
            mode: PinScreenMode.verify,
            onSuccess: _onPinVerifySuccess,
            // "Lupa PIN?" → sign out → LoginScreen (password fallback)
            onForgotPin: _onForgotPin,
          );
        }

        // ── PIN setup — setelah registrasi baru ───────────────────────────
        if (_pinSetupPending) {
          return PinScreen(
            mode: PinScreenMode.setup,
            onSuccess: _onPinSetupSuccess,
            onCancel: _onPinSetupSkip,
          );
        }

        return const MainNavigation();
      },
    );
  }
}

// ─── Splash ───────────────────────────────────────────────────────────────────

class _SplashView extends StatelessWidget {
  const _SplashView();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.backgroundDark : AppColors.background;
    final txtPrim = isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;

    return Scaffold(
      backgroundColor: bgColor,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.35),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  )
                ],
              ),
              child: const Icon(Icons.bolt, color: Colors.white, size: 36),
            ),
            const SizedBox(height: 16),
            Text('Spendly',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: txtPrim,
                  letterSpacing: -0.5,
                )),
            const SizedBox(height: 32),
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                  strokeWidth: 2.5, color: AppColors.primary),
            ),
          ],
        ),
      ),
    );
  }
}
