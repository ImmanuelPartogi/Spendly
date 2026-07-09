import 'dart:math' as math;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth/domain/services/auth_service.dart';
import 'auth/presentation/screens/login_screen.dart';
import 'auth/presentation/screens/pin_screen.dart';
import 'onboarding/presentation/screens/onboarding_screen.dart';
import '../core/navigation/main_navigation.dart';
import '../core/providers.dart';
import '../core/theme/app_colors.dart';
import '../core/auth/auth_provider.dart';
import '../core/services/auth_service_firebase.dart';

// ─────────────────────────────────────────────────────────────────────────────
// AppGate
// ─────────────────────────────────────────────────────────────────────────────

class AppGate extends ConsumerStatefulWidget {
  const AppGate({super.key});

  @override
  ConsumerState<AppGate> createState() => _AppGateState();
}

class _AppGateState extends ConsumerState<AppGate> with WidgetsBindingObserver {
  bool?  _onboardingDone;
  bool   _pinEnabled         = false;
  bool   _pinLocked          = false;
  bool   _pinSetupPending    = false;
  bool   _checkingPrefs      = true;
  bool   _appWasInBackground = false;

  String? _lastUserId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadInitialPrefs();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _appWasInBackground = true;
    } else if (state == AppLifecycleState.resumed && _appWasInBackground) {
      _appWasInBackground = false;
      if (_pinEnabled && mounted) {
        setState(() => _pinLocked = true);
      }
    }
  }

  Future<void> _loadInitialPrefs() async {
    final onboarding = await isOnboardingDone();
    if (mounted) {
      setState(() {
        _onboardingDone = onboarding;
        _checkingPrefs  = false;
      });
    }
  }

  Future<void> _reloadForNewUser(User user) async {
    if (_lastUserId == user.uid) return;
    _lastUserId = user.uid;

    ref
      ..invalidate(bottomNavIndexProvider)
      ..invalidate(selectedMonthProvider)
      ..invalidate(analyticsPeriodProvider)
      ..invalidate(analyticsCustomRangeProvider)
      ..invalidate(insightsProvider)
      ..invalidate(monthlySpendingProvider);

    final pinEnabled = await AuthService.isPinEnabled();
    final pinDecided = await AuthService.hasPinDecisionBeenMade();

    if (mounted) {
      setState(() {
        _pinEnabled      = pinEnabled;
        _pinLocked       = pinEnabled;
        _pinSetupPending = !pinEnabled && !pinDecided;
      });
    }
  }

  void _onPinVerifySuccess() {
    if (mounted) setState(() => _pinLocked = false);
  }

  Future<void> _onPinSetupSuccess() async {
    final pinEnabled = await AuthService.isPinEnabled();
    if (mounted) {
      setState(() {
        _pinSetupPending = false;
        _pinEnabled      = pinEnabled;
        _pinLocked       = false;
      });
    }
  }

  Future<void> _onPinSetupSkip() async {
    await AuthService.markPinDecisionMade();
    if (mounted) {
      setState(() {
        _pinSetupPending = false;
        _pinEnabled      = false;
        _pinLocked       = false;
      });
    }
  }

  Future<void> _onForgotPin() async {
    await AuthService.clearAllOnLogout();
    await FirebaseAuthService.signOut();
  }

  @override
  Widget build(BuildContext context) {
    final authState    = ref.watch(authStateProvider);
    final restoreReady = ref.watch(restoreReadyProvider);

    return authState.when(
      loading: () => const _SplashView(),
      error:   (_, __) => const LoginScreen(),
      data: (user) {
        if (_checkingPrefs || _onboardingDone == null) return const _SplashView();

        if (!_onboardingDone!) {
          return OnboardingScreen(
            onDone: () async {
              await markOnboardingDone();
              if (mounted) setState(() => _onboardingDone = true);
            },
          );
        }

        if (user == null) {
          if (_lastUserId != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                setState(() {
                  _lastUserId      = null;
                  _pinEnabled      = false;
                  _pinLocked       = false;
                  _pinSetupPending = false;
                });
              }
            });
          }
          return const LoginScreen();
        }

        if (!restoreReady) return const _SplashView();

        if (_lastUserId != user.uid) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _reloadForNewUser(user);
          });
          return const _SplashView();
        }

        if (_pinEnabled && _pinLocked) {
          return PinScreen(
            mode:        PinScreenMode.verify,
            onSuccess:   _onPinVerifySuccess,
            onForgotPin: _onForgotPin,
          );
        }

        if (_pinSetupPending) {
          return PinScreen(
            mode:      PinScreenMode.setup,
            onSuccess: _onPinSetupSuccess,
            onCancel:  _onPinSetupSkip,
          );
        }

        return const MainNavigation();
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SplashView
// ─────────────────────────────────────────────────────────────────────────────

class _SplashView extends StatefulWidget {
  const _SplashView();

  @override
  State<_SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<_SplashView> with TickerProviderStateMixin {

  // ── Icon entrance (scale + fade)
  late final AnimationController _iconCtrl;
  late final Animation<double>   _iconScale;
  late final Animation<double>   _iconFade;

  // ── Rotating arc ring
  late final AnimationController _ringCtrl;

  // ── Icon soft pulse
  late final AnimationController _pulseCtrl;
  late final Animation<double>   _pulseScale;

  // ── Teks "Spendly" per huruf
  late final AnimationController _textCtrl;

  // ── Tagline fade + slide
  late final AnimationController _taglineCtrl;
  late final Animation<double>   _taglineFade;
  late final Animation<Offset>   _taglineSlide;

  // ── Dot loader
  late final AnimationController _dotCtrl;

  static const _appName = 'Spendly';
  static const _tagline = 'Teman keuangan cerdas Anda'; // ← diubah ke Bahasa Indonesia

  // Durasi total animasi teks
  static const _textDelay    = 420;
  static const _perLetterMs  = 75;
  static const _textDuration = _appName.length * _perLetterMs + 150;

  @override
  void initState() {
    super.initState();

    // 1. Icon entrance — scale dari 0.5 ke 1.0 dengan easeOutBack
    _iconCtrl = AnimationController(
      vsync:    this,
      duration: const Duration(milliseconds: 520),
    )..forward();

    _iconScale = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _iconCtrl, curve: Curves.easeOutBack),
    );
    _iconFade = CurvedAnimation(parent: _iconCtrl, curve: Curves.easeOut);

    // 2. Rotating arc ring — looping
    _ringCtrl = AnimationController(
      vsync:    this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();

    // 3. Icon pulse — subtle, terus menerus
    _pulseCtrl = AnimationController(
      vsync:    this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);

    _pulseScale = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );

    // 4. Teks per huruf — mulai setelah icon selesai
    _textCtrl = AnimationController(
      vsync:    this,
      duration: const Duration(milliseconds: _textDuration),
    );
    Future.delayed(const Duration(milliseconds: _textDelay), () {
      if (mounted) _textCtrl.forward();
    });

    // 5. Tagline — muncul setelah teks selesai
    _taglineCtrl = AnimationController(
      vsync:    this,
      duration: const Duration(milliseconds: 480),
    );
    Future.delayed(
      const Duration(milliseconds: _textDelay + _textDuration + 80),
      () { if (mounted) _taglineCtrl.forward(); },
    );

    _taglineFade = CurvedAnimation(
      parent: _taglineCtrl,
      curve:  Curves.easeOut,
    );
    _taglineSlide = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end:   Offset.zero,
    ).animate(CurvedAnimation(parent: _taglineCtrl, curve: Curves.easeOutCubic));

    // 6. Dot loader — looping
    _dotCtrl = AnimationController(
      vsync:    this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _iconCtrl.dispose();
    _ringCtrl.dispose();
    _pulseCtrl.dispose();
    _textCtrl.dispose();
    _taglineCtrl.dispose();
    _dotCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark  = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.backgroundDark : AppColors.background;
    final txtPrim = isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;
    final txtSec  = txtPrim.withValues(alpha: 0.38);

    return Scaffold(
      backgroundColor: bgColor,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [

            // ── Icon + arc ring ──────────────────────────────────────
            FadeTransition(
              opacity: _iconFade,
              child: ScaleTransition(
                scale: _iconScale,
                child: SizedBox(
                  width:  104,
                  height: 104,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [

                      // Arc ring
                      AnimatedBuilder(
                        animation: _ringCtrl,
                        builder: (_, __) => CustomPaint(
                          size: const Size(104, 104),
                          painter: _ArcRingPainter(
                            progress: _ringCtrl.value,
                            color:    AppColors.primary,
                            isDark:   isDark,
                          ),
                        ),
                      ),

                      // Icon + pulse
                      ScaleTransition(
                        scale: _pulseScale,
                        child: Container(
                          width:  68,
                          height: 68,
                          decoration: BoxDecoration(
                            gradient:     AppColors.primaryGradient,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Icon(
                            Icons.bolt,
                            color: Colors.white,
                            size:  32,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 30),

            // ── "Spendly" — tiap huruf animate masuk ─────────────────
            AnimatedBuilder(
              animation: _textCtrl,
              builder: (_, __) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(_appName.length, (i) {
                    final letterStart = i / _appName.length;
                    final letterEnd   = (i + 1) / _appName.length;
                    final raw = (_textCtrl.value - letterStart) /
                        (letterEnd - letterStart);
                    final t = Curves.easeOutCubic
                        .transform(raw.clamp(0.0, 1.0));

                    return Opacity(
                      opacity: t,
                      child: Transform.translate(
                        offset: Offset(0, 14 * (1 - t)),
                        child: Text(
                          _appName[i],
                          style: TextStyle(
                            fontSize:      28,
                            fontWeight:    FontWeight.w700,
                            color:         txtPrim,
                            letterSpacing: -0.8,
                            height:        1,
                          ),
                        ),
                      ),
                    );
                  }),
                );
              },
            ),

            const SizedBox(height: 8),

            // ── Tagline ───────────────────────────────────────────────
            FadeTransition(
              opacity: _taglineFade,
              child: SlideTransition(
                position: _taglineSlide,
                child: Text(
                  _tagline,
                  style: TextStyle(
                    fontSize:      13,
                    fontWeight:    FontWeight.w400,
                    color:         txtSec,
                    letterSpacing: 0.15,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 60),

            // ── Dot loader ────────────────────────────────────────────
            AnimatedBuilder(
              animation: _dotCtrl,
              builder: (_, __) => Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(3, (i) {
                  const delay   = 0.25;
                  final phase   = ((_dotCtrl.value - i * delay) % 1.0 + 1.0) % 1.0;
                  final t       = math.sin(phase * math.pi).clamp(0.0, 1.0);
                  final opacity = 0.18 + 0.82 * t;
                  final scale   = 0.65 + 0.35 * t;
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 3.5),
                    width:  7 * scale,
                    height: 7 * scale,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primary.withValues(alpha: opacity),
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Arc Ring Painter
// ─────────────────────────────────────────────────────────────────────────────

class _ArcRingPainter extends CustomPainter {
  final double progress;
  final Color  color;
  final bool   isDark;

  const _ArcRingPainter({
    required this.progress,
    required this.color,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width  / 2;
    final cy = size.height / 2;
    final r  = size.width  / 2 - 3;

    // Track ring (dim)
    final trackPaint = Paint()
      ..style       = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color       = color.withValues(alpha: isDark ? 0.12 : 0.10);

    canvas.drawCircle(Offset(cx, cy), r, trackPaint);

    // Rotating arc dengan sweep gradient
    final arcPaint = Paint()
      ..style       = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap   = StrokeCap.round
      ..shader      = SweepGradient(
        colors:     [color.withValues(alpha: 0), color],
        startAngle: 0,
        endAngle:   math.pi * 2,
      ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: r));

    final startAngle = 2 * math.pi * progress - math.pi / 2;
    const sweepAngle = math.pi * 1.1;

    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: r),
      startAngle,
      sweepAngle,
      false,
      arcPaint,
    );
  }

  @override
  bool shouldRepaint(_ArcRingPainter old) => old.progress != progress;
}