import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/services/auth_service.dart';

enum PinScreenMode { setup, verify }

class PinScreen extends StatefulWidget {
  final PinScreenMode mode;
  final VoidCallback? onSuccess;
  final VoidCallback? onCancel;
  final VoidCallback? onForgotPin;

  const PinScreen({
    super.key,
    required this.mode,
    this.onSuccess,
    this.onCancel,
    this.onForgotPin,
  });

  @override
  State<PinScreen> createState() => _PinScreenState();
}

class _PinScreenState extends State<PinScreen> with TickerProviderStateMixin {
  String  _pin         = '';
  String? _firstPin;
  String? _errorMsg;
  bool    _isVerifying = false;

  late final AnimationController       _shakeCtrl;
  late final Animation<double>         _shakeAnim;
  late final AnimationController       _entranceCtrl;
  late final Animation<double>         _entranceFade;
  late final Animation<Offset>         _entranceSlide;
  late final AnimationController       _successCtrl;
  late final List<AnimationController> _dotCtrls;
  late final List<Animation<double>>   _dotScales;

  static const int _pinLength = 6;

  @override
  void initState() {
    super.initState();

    _shakeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 480),);
    _shakeAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0,   end: -12.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -12.0, end:  12.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin:  12.0, end:  -8.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin:  -8.0, end:   8.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin:   8.0, end:   0.0), weight: 1),
    ]).animate(CurvedAnimation(parent: _shakeCtrl, curve: Curves.easeInOut));

    _entranceCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700),);
    _entranceFade  = CurvedAnimation(
        parent: _entranceCtrl, curve: const Interval(0, 0.75, curve: Curves.easeOut),);
    _entranceSlide = Tween<Offset>(
        begin: const Offset(0, 0.04), end: Offset.zero,)
        .animate(CurvedAnimation(
            parent: _entranceCtrl,
            curve: const Interval(0, 0.75, curve: Curves.easeOutCubic),),);

    _successCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 250),);

    _dotCtrls = List.generate(
      _pinLength,
      (_) => AnimationController(
          vsync: this, duration: const Duration(milliseconds: 220),),
    );
    _dotScales = List.generate(_pinLength, (i) {
      return Tween<double>(begin: 0.4, end: 1.0).animate(
        CurvedAnimation(parent: _dotCtrls[i], curve: Curves.easeOutBack),
      );
    });

    _entranceCtrl.forward();
  }

  @override
  void dispose() {
    _shakeCtrl.dispose();
    _entranceCtrl.dispose();
    _successCtrl.dispose();
    for (final c in _dotCtrls) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _onKey(String key) async {
    if (key == 'del') {
      if (_pin.isNotEmpty) {
        unawaited(_dotCtrls[_pin.length - 1].reverse());
        unawaited(HapticFeedback.lightImpact());
        setState(() { _pin = _pin.substring(0, _pin.length - 1); _errorMsg = null; });
      }
      return;
    }

    if (_pin.length >= _pinLength) return;

    unawaited(HapticFeedback.lightImpact());
    unawaited(_dotCtrls[_pin.length].forward(from: 0));
    final newPin = _pin + key;
    setState(() => _pin = newPin);

    if (newPin.length < _pinLength) return;

    await Future.delayed(const Duration(milliseconds: 80));
    await _processPin(newPin);
  }

  Future<void> _processPin(String pin) async {
    if (widget.mode == PinScreenMode.setup) {
      if (_firstPin == null) {
        unawaited(HapticFeedback.mediumImpact());
        setState(() { _firstPin = pin; _pin = ''; _errorMsg = null; });
        for (final c in _dotCtrls) {
          unawaited(c.reverse());
        }
      } else {
        if (_firstPin == pin) {
          unawaited(HapticFeedback.heavyImpact());
          await AuthService.setPin(pin);
          widget.onSuccess?.call();
        } else {
          await _triggerError('PIN tidak cocok, coba lagi');
          setState(() => _firstPin = null);
        }
      }
    } else {
      setState(() => _isVerifying = true);
      final ok = await AuthService.verifyPin(pin);
      if (ok) {
        unawaited(HapticFeedback.heavyImpact());
        widget.onSuccess?.call();
      } else {
        await _triggerError('PIN salah, coba lagi');
      }
      if (mounted) setState(() => _isVerifying = false);
    }
  }

  Future<void> _triggerError(String msg) async {
    unawaited(HapticFeedback.vibrate());
    await _shakeCtrl.forward(from: 0);
    if (mounted) {
      setState(() { _pin = ''; _errorMsg = msg; });
      for (final c in _dotCtrls) {
        unawaited(c.reverse());
      }
    }
  }

  String get _title {
    if (widget.mode == PinScreenMode.setup) {
      return _firstPin == null ? 'Buat PIN Baru' : 'Konfirmasi PIN';
    }
    return 'Masukkan PIN';
  }

  String get _subtitle {
    if (widget.mode == PinScreenMode.setup) {
      return _firstPin == null
          ? 'Buat 6 digit PIN untuk keamanan akunmu'
          : 'Masukkan ulang PIN untuk konfirmasi';
    }
    return 'Masukkan PIN untuk membuka Spendly';
  }

  @override
  Widget build(BuildContext context) {
    final isDark  = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.backgroundDark : const Color(0xFFF5F7FF);

    return Scaffold(
      backgroundColor: bgColor,
      resizeToAvoidBottomInset: false,
      body: Stack(children: [
        _PinBackground(isDark: isDark),
        SafeArea(
          child: FadeTransition(
            opacity: _entranceFade,
            child: SlideTransition(
              position: _entranceSlide,
              child: Column(children: [
                // ── Top bar ──────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (widget.onCancel != null)
                        _TopBackButton(isDark: isDark, onTap: widget.onCancel!)
                      else
                        const SizedBox(width: 40),

                      if (widget.mode == PinScreenMode.setup)
                        _SetupStepBadge(isDark: isDark, isConfirm: _firstPin != null),

                      const SizedBox(width: 40),
                    ],
                  ),
                ),

                const Spacer(flex: 2),

                // ── Header section ───────────────────────────────────────
                _PinHeaderSection(isDark: isDark, title: _title, subtitle: _subtitle),

                const SizedBox(height: 52),

                // ── PIN dots ─────────────────────────────────────────────
                AnimatedBuilder(
                  animation: _shakeAnim,
                  builder: (_, child) => Transform.translate(
                      offset: Offset(_shakeAnim.value, 0), child: child,),
                  child: _PinDotsRow(
                    filledCount: _pin.length,
                    pinLength: _pinLength,
                    hasError: _errorMsg != null,
                    dotScales: _dotScales,
                    isDark: isDark,
                  ),
                ),

                // ── Error message ────────────────────────────────────────
                SizedBox(
                  height: 50,
                  child: Center(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 220),
                      transitionBuilder: (child, anim) => FadeTransition(
                        opacity: anim,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0, 0.3),
                            end: Offset.zero,
                          ).animate(anim),
                          child: child,
                        ),
                      ),
                      child: _errorMsg != null
                          ? _PinErrorPill(
                              key: ValueKey(_errorMsg),
                              message: _errorMsg!,)
                          : const SizedBox.shrink(key: ValueKey('none')),
                    ),
                  ),
                ),

                const Spacer(flex: 3),

                // ── Numpad ───────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: _Numpad(
                    onKey: _onKey,
                    isDark: isDark,
                    isLoading: _isVerifying,
                  ),
                ),

                // ── Forgot PIN ───────────────────────────────────────────
                if (widget.mode == PinScreenMode.verify &&
                    widget.onForgotPin != null) ...[
                  const SizedBox(height: 28),
                  GestureDetector(
                    onTap: widget.onForgotPin,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.primary.withValues(alpha: 0.10)
                            : AppColors.primary.withValues(alpha: 0.07),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.18),
                        ),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.lock_reset_rounded,
                            size: 13, color: AppColors.primary.withValues(alpha: 0.8),),
                        const SizedBox(width: 6),
                        const Text(
                          'Lupa PIN? Gunakan password',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.1,
                          ),
                        ),
                      ],),
                    ),
                  ),
                ],

                const SizedBox(height: 36),
              ],),
            ),
          ),
        ),
      ],),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Background
// ─────────────────────────────────────────────────────────────────────────────

class _PinBackground extends StatelessWidget {
  final bool isDark;
  const _PinBackground({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(child: Stack(children: [
      Positioned(
        top: -80, left: -80,
        child: Container(
          width: 280, height: 280,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(colors: [
              AppColors.primary.withValues(alpha: isDark ? 0.11 : 0.09),
              Colors.transparent,
            ],),
          ),
        ),
      ),
      Positioned(
        bottom: -100, right: -80,
        child: Container(
          width: 320, height: 320,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(colors: [
              AppColors.accentPurple.withValues(alpha: isDark ? 0.09 : 0.06),
              Colors.transparent,
            ],),
          ),
        ),
      ),
      if (!isDark)
        Positioned.fill(child: CustomPaint(painter: _PinDotGrid())),
    ],),);
  }
}

class _PinDotGrid extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.038)
      ..style = PaintingStyle.fill;
    const spacing = 26.0;
    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 1.0, paint);
      }
    }
  }
  @override
  bool shouldRepaint(_) => false;
}

// ─────────────────────────────────────────────────────────────────────────────
// Top Bar Elements
// ─────────────────────────────────────────────────────────────────────────────

class _TopBackButton extends StatelessWidget {
  final bool isDark;
  final VoidCallback onTap;
  const _TopBackButton({required this.isDark, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40, height: 40,
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? AppColors.borderDark : const Color(0xFFE8ECFF),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
              blurRadius: 8, offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          Icons.arrow_back_ios_new_rounded, size: 14,
          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
        ),
      ),
    );
  }
}

class _SetupStepBadge extends StatelessWidget {
  final bool isDark;
  final bool isConfirm;
  const _SetupStepBadge({required this.isDark, required this.isConfirm});

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      child: Container(
        key: ValueKey(isConfirm),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isConfirm
              ? AppColors.income.withValues(alpha: 0.10)
              : AppColors.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isConfirm
                ? AppColors.income.withValues(alpha: 0.25)
                : AppColors.primary.withValues(alpha: 0.18),
          ),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 16, height: 16,
            decoration: BoxDecoration(
              color: isConfirm
                  ? AppColors.income.withValues(alpha: 0.15)
                  : AppColors.primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                isConfirm ? '2' : '1',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  color: isConfirm ? AppColors.income : AppColors.primary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            isConfirm ? 'Konfirmasi PIN' : 'Langkah 1 dari 2',
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: isConfirm ? AppColors.income : AppColors.primary,
              letterSpacing: -0.1,
            ),
          ),
        ],),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Pin Header
// ─────────────────────────────────────────────────────────────────────────────

class _PinHeaderSection extends StatelessWidget {
  final bool isDark;
  final String title, subtitle;
  const _PinHeaderSection({
    required this.isDark, required this.title, required this.subtitle,});

  @override
  Widget build(BuildContext context) {
    final txtPrim = isDark ? AppColors.textPrimaryDark   : AppColors.textPrimary;
    final txtSec  = isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;

    return Column(children: [
      Container(
        width: 64, height: 64,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.primary,
              Color.lerp(AppColors.primary, AppColors.accentPurple, 0.45)!,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.32),
              blurRadius: 20,
              offset: const Offset(0, 8),
              spreadRadius: -4,
            ),
          ],
        ),
        child: const Icon(Icons.bolt_rounded, color: Colors.white, size: 32),
      ),

      const SizedBox(height: 28),

      AnimatedSwitcher(
        duration: const Duration(milliseconds: 280),
        transitionBuilder: (child, anim) => FadeTransition(
          opacity: anim,
          child: SlideTransition(
            position: Tween<Offset>(
                begin: const Offset(0, 0.12), end: Offset.zero,).animate(anim),
            child: child,
          ),
        ),
        child: Text(
          title,
          key: ValueKey(title),
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: txtPrim,
            letterSpacing: -0.8,
            height: 1.1,
          ),
        ),
      ),

      const SizedBox(height: 8),

      AnimatedSwitcher(
        duration: const Duration(milliseconds: 280),
        child: Text(
          subtitle,
          key: ValueKey(subtitle),
          style: TextStyle(
            fontSize: 14,
            color: txtSec,
            height: 1.45,
            fontWeight: FontWeight.w400,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    ],);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PIN Dots
// ─────────────────────────────────────────────────────────────────────────────

class _PinDotsRow extends StatelessWidget {
  final int filledCount, pinLength;
  final bool hasError, isDark;
  final List<Animation<double>> dotScales;

  const _PinDotsRow({
    required this.filledCount, required this.pinLength,
    required this.hasError, required this.dotScales, required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final emptyColor  = isDark ? AppColors.surfaceDark : Colors.white;
    final emptyBorder = isDark ? AppColors.borderDark  : const Color(0xFFDDE2F0);
    final filledColor = hasError ? AppColors.expense : AppColors.primary;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(pinLength, (i) {
        final filled = i < filledCount;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: ScaleTransition(
            scale: dotScales[i],
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              width:  filled ? 18 : 14,
              height: filled ? 18 : 14,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: filled ? filledColor : emptyColor,
                border: Border.all(
                  color: filled ? filledColor : emptyBorder,
                  width: filled ? 0 : 1.5,
                ),
                boxShadow: filled
                    ? [
                        BoxShadow(
                          color: filledColor.withValues(alpha: 0.40),
                          blurRadius: 10,
                          spreadRadius: -1,
                        ),
                      ]
                    : [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
                          blurRadius: 4, offset: const Offset(0, 1),
                        ),
                      ],
              ),
            ),
          ),
        );
      }),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Error Pill
// ─────────────────────────────────────────────────────────────────────────────

class _PinErrorPill extends StatelessWidget {
  final String message;
  const _PinErrorPill({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.expense.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.expense.withValues(alpha: 0.22)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 16, height: 16,
          decoration: BoxDecoration(
            color: AppColors.expense.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: const Center(
            child: Icon(Icons.close_rounded, size: 10, color: AppColors.expense),
          ),
        ),
        const SizedBox(width: 7),
        Text(
          message,
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.expense,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.1,
          ),
        ),
      ],),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Numpad
// ─────────────────────────────────────────────────────────────────────────────

class _Numpad extends StatelessWidget {
  final Future<void> Function(String) onKey;
  final bool isDark, isLoading;

  const _Numpad({
    required this.onKey,
    required this.isDark,
    required this.isLoading,
  });

  static const _rows = [
    ['1', '2', '3'],
    ['4', '5', '6'],
    ['7', '8', '9'],
    ['', '0', 'del'],
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: _rows.map((row) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: row.map((key) {
              if (key.isEmpty) {
                return const SizedBox(width: 74, height: 74);
              }
              return _NumKey(
                value: key,
                isDark: isDark,
                isLoading: isLoading && key == 'del',
                onTap: onKey,
              );
            }).toList(),
          ),
        );
      }).toList(),
    );
  }
}

class _NumKey extends StatefulWidget {
  final String value;
  final bool isDark, isLoading;
  final Future<void> Function(String) onTap;

  const _NumKey({
    required this.value, required this.isDark,
    required this.isLoading, required this.onTap,
  });

  @override
  State<_NumKey> createState() => _NumKeyState();
}

class _NumKeyState extends State<_NumKey> with SingleTickerProviderStateMixin {
  late final AnimationController _pressCtrl;
  late final Animation<double>   _scaleAnim;

  @override
  void initState() {
    super.initState();
    _pressCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 75),
      reverseDuration: const Duration(milliseconds: 150),
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.86)
        .animate(CurvedAnimation(parent: _pressCtrl, curve: Curves.easeOut));
  }

  @override
  void dispose() { _pressCtrl.dispose(); super.dispose(); }

  bool get _isSpecial => widget.value == 'del';

  @override
  Widget build(BuildContext context) {
    final txtPrim  = widget.isDark ? AppColors.textPrimaryDark   : AppColors.textPrimary;
    final txtSec   = widget.isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;
    final keyColor = widget.isDark ? AppColors.surfaceDark : Colors.white;
    final bdrColor = widget.isDark ? AppColors.borderDark  : const Color(0xFFE8ECFF);

    Widget keyChild;
    if (widget.value == 'del') {
      keyChild = widget.isLoading
          ? SizedBox(
              width: 18, height: 18,
              child: CircularProgressIndicator(
                  color: txtSec, strokeWidth: 2,),)
          : Icon(Icons.backspace_outlined, color: txtPrim, size: 20);
    } else {
      keyChild = Text(
        widget.value,
        style: TextStyle(
          fontSize: 26,
          fontWeight: FontWeight.w400,
          color: txtPrim,
          letterSpacing: -0.5,
          height: 1.0,
        ),
      );
    }

    return GestureDetector(
      onTapDown: (_) => _pressCtrl.forward(),
      onTapUp: (_) {
        _pressCtrl.reverse();
        widget.onTap(widget.value);
      },
      onTapCancel: () => _pressCtrl.reverse(),
      child: ScaleTransition(
        scale: _scaleAnim,
        child: Container(
          width: 74, height: 74,
          margin: const EdgeInsets.symmetric(vertical: 4),
          decoration: _isSpecial
              ? null
              : BoxDecoration(
                  color: keyColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: bdrColor, width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: widget.isDark ? 0.22 : 0.055),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                      spreadRadius: -2,
                    ),
                  ],
                ),
          child: Center(child: keyChild),
        ),
      ),
    );
  }
}