import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/auth_service_firebase.dart';

enum _AuthStep { email, passwordFallback, register }

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with TickerProviderStateMixin {
  final _emailCtrl   = TextEditingController();
  final _passCtrl    = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _formKey     = GlobalKey<FormState>();

  _AuthStep _step        = _AuthStep.email;
  bool      _isLoading   = false;
  bool      _obscurePass = true;
  bool      _obscureConf = true;
  String?   _errorMsg;
  String?   _checkedEmail;

  // ── Animations ────────────────────────────────────────────────────────────

  late final AnimationController       _entranceCtrl;
  late final Animation<double>         _entranceFade;
  late final Animation<Offset>         _entranceSlide;
  late final AnimationController       _logoCtrl;
  late final Animation<double>         _logoScale;
  late final Animation<double>         _logoFade;
  late final AnimationController       _stepCtrl;
  late final Animation<double>         _stepFade;
  late final Animation<Offset>         _stepSlide;

  @override
  void initState() {
    super.initState();

    _entranceCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900),);
    _entranceFade = CurvedAnimation(
        parent: _entranceCtrl,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOut),);
    _entranceSlide =
        Tween<Offset>(begin: const Offset(0, 0.05), end: Offset.zero).animate(
            CurvedAnimation(
                parent: _entranceCtrl,
                curve: const Interval(0.0, 0.7, curve: Curves.easeOutCubic),),);

    _logoCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600),);
    _logoScale = Tween<double>(begin: 0.7, end: 1.0).animate(
        CurvedAnimation(parent: _logoCtrl, curve: Curves.easeOutBack),);
    _logoFade = CurvedAnimation(parent: _logoCtrl, curve: Curves.easeOut);

    _stepCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 280),);
    _stepFade  = CurvedAnimation(parent: _stepCtrl, curve: Curves.easeOut);
    _stepSlide = Tween<Offset>(begin: const Offset(0.03, 0), end: Offset.zero)
        .animate(CurvedAnimation(
            parent: _stepCtrl, curve: Curves.easeOutCubic,),);

    _logoCtrl.forward();
    _entranceCtrl.forward();
    _stepCtrl.value = 1.0;
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    _entranceCtrl.dispose();
    _logoCtrl.dispose();
    _stepCtrl.dispose();
    super.dispose();
  }

  // ── Transition ────────────────────────────────────────────────────────────

  Future<void> _transitionTo(_AuthStep step) async {
    await _stepCtrl.reverse();
    if (!mounted) return;
    setState(() {
      _step     = step;
      _errorMsg = null;
    });
    unawaited(_stepCtrl.forward());
  }

  // ── Email: cek eksistensi akun ────────────────────────────────────────────

  Future<bool> _emailExists(String email) async {
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email, password: '___spendly_check___',);
      return true;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') return false;
      if (e.code == 'wrong-password' ||
          e.code == 'invalid-credential' ||
          e.code == 'invalid-login-credentials') {
        return true;
      }
      rethrow;
    }
  }

  Future<void> _continueWithEmail() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) {
      setState(() => _errorMsg = 'Email wajib diisi');
      return;
    }
    if (!RegExp(r'^[\w.+-]+@[\w-]+\.[a-z]{2,}$', caseSensitive: false)
        .hasMatch(email)) {
      setState(() => _errorMsg = 'Format email tidak valid');
      return;
    }

    setState(() { _isLoading = true; _errorMsg = null; });
    try {
      final exists = await _emailExists(email);
      if (!mounted) return;

      if (!exists) {
        setState(() =>
            _errorMsg = 'Akun tidak ditemukan. Silakan daftar terlebih dahulu.',);
        return;
      }

      _checkedEmail = email;
      await _transitionTo(_AuthStep.passwordFallback);
    } on FirebaseAuthException catch (e) {
      if (mounted) setState(() => _errorMsg = _friendlyError(e.code));
    } catch (_) {
      if (mounted) {
        setState(() =>
            _errorMsg = 'Terjadi kesalahan. Periksa koneksi internet.',);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Password login ────────────────────────────────────────────────────────
  //
  // Setelah login berhasil, AppGate menangani sisanya:
  //   • Jika PIN ada di storage → tampilkan PinScreen.verify
  //   • Jika PIN belum pernah disetup → tampilkan PinScreen.setup

  Future<void> _loginWithPassword() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() { _isLoading = true; _errorMsg = null; });
    try {
      await FirebaseAuthService.signInWithEmail(_checkedEmail!, _passCtrl.text);
    } on FirebaseAuthException catch (e) {
      if (mounted) setState(() => _errorMsg = _friendlyError(e.code));
    } catch (_) {
      if (mounted) setState(() => _errorMsg = 'Terjadi kesalahan. Coba lagi.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Register ──────────────────────────────────────────────────────────────
  //
  // Setelah register berhasil, AppGate otomatis tampilkan PinScreen.setup
  // karena PIN belum ada di storage dan decision belum dibuat.

  Future<void> _register() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() { _isLoading = true; _errorMsg = null; });
    try {
      await FirebaseAuthService.registerWithEmail(
        _emailCtrl.text.trim(),
        _passCtrl.text,
      );
    } on FirebaseAuthException catch (e) {
      if (mounted) setState(() => _errorMsg = _friendlyError(e.code));
    } catch (_) {
      if (mounted) setState(() => _errorMsg = 'Terjadi kesalahan. Coba lagi.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Forgot password ───────────────────────────────────────────────────────

  Future<void> _forgotPassword() async {
    final email = (_checkedEmail ?? _emailCtrl.text).trim();
    if (email.isEmpty) return;
    setState(() { _isLoading = true; _errorMsg = null; });
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Row(children: [
            Container(
              width: 24, height: 24,
              decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,),
              child: const Icon(Icons.check_rounded,
                  color: Colors.white, size: 14,),
            ),
            const SizedBox(width: 10),
            Text('Link reset dikirim ke $email',
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w500,),),
          ],),
          backgroundColor: AppColors.income,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 0,
        ),);
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) setState(() => _errorMsg = _friendlyError(e.code));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _friendlyError(String code) {
    switch (code) {
      case 'user-not-found':
        return 'Akun tidak ditemukan';
      case 'wrong-password':
      case 'invalid-credential':
      case 'invalid-login-credentials':
        return 'Password salah';
      case 'email-already-in-use':
        return 'Email sudah digunakan akun lain';
      case 'weak-password':
        return 'Password minimal 6 karakter';
      case 'invalid-email':
        return 'Format email tidak valid';
      case 'too-many-requests':
        return 'Terlalu banyak percobaan. Coba beberapa menit lagi';
      case 'network-request-failed':
        return 'Tidak ada koneksi internet';
      default:
        return 'Terjadi kesalahan ($code)';
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final size   = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : const Color(0xFFF5F7FF),
      body: Stack(children: [
        _BackgroundDecoration(isDark: isDark, size: size),
        SafeArea(
          child: FadeTransition(
            opacity: _entranceFade,
            child: SlideTransition(
              position: _entranceSlide,
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 16),
                          SizedBox(
                            height: 48,
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 200),
                              child: _step != _AuthStep.email
                                  ? Align(
                                      alignment: Alignment.centerLeft,
                                      child: _BackBtn(
                                        key: const ValueKey('back'),
                                        isDark: isDark,
                                        onTap: () =>
                                            _transitionTo(_AuthStep.email),
                                      ),
                                    )
                                  : const SizedBox.shrink(
                                      key: ValueKey('empty'),),
                            ),
                          ),
                          const SizedBox(height: 12),
                          ScaleTransition(
                            scale: _logoScale,
                            child: FadeTransition(
                              opacity: _logoFade,
                              child: _BrandLogo(isDark: isDark),
                            ),
                          ),
                          const SizedBox(height: 24),
                          _TitleBlock(
                            isDark: isDark,
                            step: _step,
                            email: _checkedEmail,
                          ),
                          const SizedBox(height: 32),
                          FadeTransition(
                            opacity: _stepFade,
                            child: SlideTransition(
                              position: _stepSlide,
                              child: _FormCard(
                                isDark: isDark,
                                child: Form(
                                  key: _formKey,
                                  child: _buildStepContent(isDark: isDark),
                                ),
                              ),
                            ),
                          ),
                          const Spacer(),
                          const SizedBox(height: 20),
                          _buildFooter(isDark),
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],),
    );
  }

  Widget _buildStepContent({required bool isDark}) {
    switch (_step) {
      case _AuthStep.email:
        return _buildEmailStep(isDark: isDark);
      case _AuthStep.register:
        return _buildRegisterStep(isDark: isDark);
      case _AuthStep.passwordFallback:
        return _buildPasswordStep(isDark: isDark);
    }
  }

  Widget _buildEmailStep({required bool isDark}) {
    return Column(children: [
      _ProFormField(
        controller: _emailCtrl,
        label: 'Alamat Email',
        hint: 'nama@email.com',
        icon: Icons.alternate_email_rounded,
        isDark: isDark,
        keyboardType: TextInputType.emailAddress,
        validator: (v) {
          if (v == null || v.trim().isEmpty) return 'Email wajib diisi';
          if (!v.contains('@')) return 'Format email tidak valid';
          return null;
        },
      ),
      if (_errorMsg != null) ...[
        const SizedBox(height: 12),
        _ErrorBanner(message: _errorMsg!),
      ],
      const SizedBox(height: 20),
      _PrimaryButton(
        isLoading: _isLoading,
        label: 'Lanjutkan',
        icon: Icons.arrow_forward_rounded,
        onTap: _isLoading ? null : _continueWithEmail,
      ),
    ],);
  }

  Widget _buildPasswordStep({required bool isDark}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _EmailChip(email: _checkedEmail ?? _emailCtrl.text, isDark: isDark),
        const SizedBox(height: 16),
        _ProFormField(
          controller: _passCtrl,
          label: 'Password',
          hint: 'Masukkan password',
          icon: Icons.lock_outline_rounded,
          isDark: isDark,
          obscureText: _obscurePass,
          onToggleObscure: () =>
              setState(() => _obscurePass = !_obscurePass),
          validator: (v) {
            if (v == null || v.isEmpty) return 'Password wajib diisi';
            return null;
          },
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: GestureDetector(
            onTap: _isLoading ? null : _forgotPassword,
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 4, horizontal: 2),
              child: Text(
                'Lupa password?',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.1,
                ),
              ),
            ),
          ),
        ),
        if (_errorMsg != null) ...[
          const SizedBox(height: 8),
          _ErrorBanner(message: _errorMsg!),
        ],
        const SizedBox(height: 16),
        _PrimaryButton(
          isLoading: _isLoading,
          label: 'Masuk ke Akun',
          icon: Icons.login_rounded,
          onTap: _isLoading ? null : _loginWithPassword,
        ),
      ],
    );
  }

  Widget _buildRegisterStep({required bool isDark}) {
    return Column(children: [
      _ProFormField(
        controller: _emailCtrl,
        label: 'Alamat Email',
        hint: 'nama@email.com',
        icon: Icons.alternate_email_rounded,
        isDark: isDark,
        keyboardType: TextInputType.emailAddress,
        validator: (v) {
          if (v == null || v.trim().isEmpty) return 'Email wajib diisi';
          if (!v.contains('@')) return 'Format email tidak valid';
          return null;
        },
      ),
      const SizedBox(height: 12),
      _ProFormField(
        controller: _passCtrl,
        label: 'Password',
        hint: 'Minimal 6 karakter',
        icon: Icons.lock_outline_rounded,
        isDark: isDark,
        obscureText: _obscurePass,
        onToggleObscure: () =>
            setState(() => _obscurePass = !_obscurePass),
        validator: (v) {
          if (v == null || v.isEmpty) return 'Password wajib diisi';
          if (v.length < 6) return 'Minimal 6 karakter';
          return null;
        },
      ),
      const SizedBox(height: 12),
      _ProFormField(
        controller: _confirmCtrl,
        label: 'Konfirmasi Password',
        hint: 'Ulangi password',
        icon: Icons.lock_outline_rounded,
        isDark: isDark,
        obscureText: _obscureConf,
        onToggleObscure: () =>
            setState(() => _obscureConf = !_obscureConf),
        validator: (v) {
          if (v != _passCtrl.text) return 'Password tidak cocok';
          return null;
        },
      ),
      if (_errorMsg != null) ...[
        const SizedBox(height: 12),
        _ErrorBanner(message: _errorMsg!),
      ],
      const SizedBox(height: 20),
      _PrimaryButton(
        isLoading: _isLoading,
        label: 'Buat Akun',
        icon: Icons.person_add_rounded,
        onTap: _isLoading ? null : _register,
      ),
      const SizedBox(height: 16),
      _InfoChip(
        icon: Icons.shield_outlined,
        text: 'Setelah mendaftar, kamu akan membuat PIN keamanan',
        isDark: isDark,
      ),
    ],);
  }

  Widget _buildFooter(bool isDark) {
    if (_step != _AuthStep.email) return const SizedBox.shrink();
    final txtSec =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;
    return Center(
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Text('Belum punya akun?  ',
            style: TextStyle(
                fontSize: 14, color: txtSec, fontWeight: FontWeight.w400,),),
        GestureDetector(
          onTap: () {
            _passCtrl.clear();
            _confirmCtrl.clear();
            _transitionTo(_AuthStep.register);
          },
          child: const Text(
            'Daftar sekarang',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2,
            ),
          ),
        ),
      ],),
    );
  }
}

// ─── Sub-widgets (tidak berubah) ──────────────────────────────────────────────

class _BrandLogo extends StatelessWidget {
  final bool isDark;
  const _BrandLogo({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Container(
        width: 50, height: 50,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.primary,
              Color.lerp(AppColors.primary, AppColors.accentPurple, 0.5)!,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.30),
              blurRadius: 16, offset: const Offset(0, 6), spreadRadius: -2,
            ),
          ],
        ),
        child: const Icon(Icons.bolt_rounded, color: Colors.white, size: 26),
      ),
      const SizedBox(width: 12),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Spendly',
            style: TextStyle(
              fontSize: 20, fontWeight: FontWeight.w800,
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
              letterSpacing: -0.5,
            ),),
        Text('Kelola keuanganmu',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
              fontWeight: FontWeight.w400,
            ),),
      ],),
    ],);
  }
}

class _TitleBlock extends StatelessWidget {
  final bool isDark;
  final _AuthStep step;
  final String? email;
  const _TitleBlock({required this.isDark, required this.step, this.email});

  @override
  Widget build(BuildContext context) {
    final txtPrim = isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;
    final txtSec  = isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;

    final title = switch (step) {
      _AuthStep.email            => 'Selamat\nDatang Kembali',
      _AuthStep.register         => 'Buat Akun\nBaru',
      _AuthStep.passwordFallback => 'Masukkan\nPassword',
    };
    final subtitle = switch (step) {
      _AuthStep.email            => 'Masuk untuk melanjutkan pengelolaan keuanganmu.',
      _AuthStep.register         => 'Daftar gratis dan mulai lacak pengeluaranmu hari ini.',
      _AuthStep.passwordFallback => 'Verifikasi identitasmu untuk melanjutkan.',
    };

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      AnimatedSwitcher(
        duration: const Duration(milliseconds: 280),
        transitionBuilder: (child, anim) => FadeTransition(
          opacity: anim,
          child: SlideTransition(
            position: Tween<Offset>(
                    begin: const Offset(0, 0.06), end: Offset.zero,)
                .animate(anim),
            child: child,
          ),
        ),
        child: Text(title,
            key: ValueKey(step),
            style: TextStyle(
              fontSize: 32, fontWeight: FontWeight.w800,
              color: txtPrim, letterSpacing: -1.2, height: 1.1,
            ),),
      ),
      const SizedBox(height: 8),
      AnimatedSwitcher(
        duration: const Duration(milliseconds: 280),
        child: Text(subtitle,
            key: ValueKey('sub_$step'),
            style: TextStyle(
              fontSize: 14.5, color: txtSec, height: 1.5, fontWeight: FontWeight.w400,
            ),),
      ),
    ],);
  }
}

class _FormCard extends StatelessWidget {
  final bool isDark;
  final Widget child;
  const _FormCard({required this.isDark, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? AppColors.borderDark : const Color(0xFFE8ECFF),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.30)
                : AppColors.primary.withValues(alpha: 0.06),
            blurRadius: 40, offset: const Offset(0, 12), spreadRadius: -4,
          ),
        ],
      ),
      padding: const EdgeInsets.all(22),
      child: child,
    );
  }
}

class _EmailChip extends StatelessWidget {
  final String email;
  final bool isDark;
  const _EmailChip({required this.email, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.primary.withValues(alpha: 0.10)
            : AppColors.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.18)),
      ),
      child: Row(children: [
        Container(
          width: 32, height: 32,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.alternate_email_rounded,
              size: 15, color: AppColors.primary,),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Masuk sebagai',
                style: TextStyle(
                  fontSize: 10.5,
                  color: AppColors.primary.withValues(alpha: 0.7),
                  fontWeight: FontWeight.w500, letterSpacing: 0.2,
                ),),
            const SizedBox(height: 1),
            Text(email,
                style: const TextStyle(
                  fontSize: 13.5, fontWeight: FontWeight.w700,
                  color: AppColors.primary, letterSpacing: -0.2,
                ),),
          ],),
        ),
      ],),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool isDark;
  const _InfoChip({required this.icon, required this.text, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final color = isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;
    return Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(icon, size: 13, color: color.withValues(alpha: 0.6)),
      const SizedBox(width: 6),
      Flexible(
        child: Text(text,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12, color: color.withValues(alpha: 0.6),
              height: 1.5, fontWeight: FontWeight.w400,
            ),),
      ),
    ],);
  }
}

class _BackBtn extends StatelessWidget {
  final bool isDark;
  final VoidCallback onTap;
  const _BackBtn({super.key, required this.isDark, required this.onTap});

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
        child: Icon(Icons.arrow_back_ios_new_rounded, size: 14,
            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,),
      ),
    );
  }
}

class _BackgroundDecoration extends StatelessWidget {
  final bool isDark;
  final Size size;
  const _BackgroundDecoration({required this.isDark, required this.size});

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Stack(children: [
        Positioned(
          top: -120, right: -100,
          child: Container(
            width: 350, height: 350,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: [
                AppColors.primary.withValues(alpha: isDark ? 0.13 : 0.10),
                Colors.transparent,
              ],),
            ),
          ),
        ),
        Positioned(
          bottom: -80, left: -80,
          child: Container(
            width: 280, height: 280,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: [
                AppColors.accentPurple.withValues(alpha: isDark ? 0.09 : 0.07),
                Colors.transparent,
              ],),
            ),
          ),
        ),
        if (!isDark)
          Positioned.fill(child: CustomPaint(painter: _DotGridPainter())),
      ],),
    );
  }
}

class _DotGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.04)
      ..style = PaintingStyle.fill;
    const spacing = 26.0;
    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 1.1, paint);
      }
    }
  }
  @override
  bool shouldRepaint(_) => false;
}

class _ProFormField extends StatefulWidget {
  final TextEditingController controller;
  final String label, hint;
  final IconData icon;
  final bool isDark, obscureText;
  final VoidCallback? onToggleObscure;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  const _ProFormField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    required this.isDark,
    this.obscureText = false,
    this.onToggleObscure,
    this.keyboardType,
    this.validator,
  });

  @override
  State<_ProFormField> createState() => _ProFormFieldState();
}

class _ProFormFieldState extends State<_ProFormField> {
  final _focus   = FocusNode();
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _focus.addListener(() => setState(() {}));
  }

  @override
  void dispose() { _focus.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final isFocused = _focus.hasFocus;
    final txtPrim   = widget.isDark ? AppColors.textPrimaryDark   : AppColors.textPrimary;
    final txtHint   = widget.isDark ? AppColors.textHintDark      : AppColors.textHint;
    final txtSec    = widget.isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;
    final surfColor = widget.isDark ? AppColors.surfaceDark : const Color(0xFFF8F9FF);
    final bdrColor  = widget.isDark ? AppColors.borderDark : const Color(0xFFE8ECFF);

    final borderColor = isFocused
        ? AppColors.primary.withValues(alpha: 0.55)
        : _hasError
            ? AppColors.expense.withValues(alpha: 0.55)
            : bdrColor;

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.only(left: 1, bottom: 7),
        child: Text(widget.label,
            style: TextStyle(
              fontSize: 12.5, fontWeight: FontWeight.w600,
              color: isFocused ? AppColors.primary : txtSec,
              letterSpacing: 0.1,
            ),),
      ),
      AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: isFocused
              ? (widget.isDark ? AppColors.surfaceDark : Colors.white)
              : surfColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor, width: isFocused ? 1.5 : 1),
          boxShadow: isFocused
              ? [BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  blurRadius: 16, offset: const Offset(0, 4),),]
              : null,
        ),
        child: TextFormField(
          controller: widget.controller,
          focusNode: _focus,
          obscureText: widget.obscureText,
          keyboardType: widget.keyboardType,
          style: TextStyle(
            color: txtPrim, fontSize: 14.5,
            fontWeight: FontWeight.w500, letterSpacing: -0.1,
          ),
          decoration: InputDecoration(
            hintText: widget.hint,
            hintStyle: TextStyle(color: txtHint, fontSize: 14, fontWeight: FontWeight.w400),
            prefixIcon: Padding(
              padding: const EdgeInsets.only(left: 4, right: 2),
              child: Icon(widget.icon, size: 17,
                  color: isFocused ? AppColors.primary : txtSec.withValues(alpha: 0.6),),
            ),
            suffixIcon: widget.onToggleObscure != null
                ? IconButton(
                    padding: EdgeInsets.zero,
                    icon: Icon(
                      widget.obscureText
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      size: 17, color: txtSec.withValues(alpha: 0.6),
                    ),
                    onPressed: widget.onToggleObscure,)
                : null,
            border:            InputBorder.none,
            enabledBorder:     InputBorder.none,
            focusedBorder:     InputBorder.none,
            errorBorder:       InputBorder.none,
            focusedErrorBorder: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
            fillColor: Colors.transparent,
            filled: false,
            isDense: true,
            errorStyle: const TextStyle(height: 0, fontSize: 0),
          ),
          validator: (v) {
            final result = widget.validator?.call(v);
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) setState(() => _hasError = result != null);
            });
            return result;
          },
        ),
      ),
    ],);
  }
}

class _PrimaryButton extends StatefulWidget {
  final bool isLoading;
  final String label;
  final IconData icon;
  final VoidCallback? onTap;
  const _PrimaryButton({
    required this.isLoading,
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  State<_PrimaryButton> createState() => _PrimaryButtonState();
}

class _PrimaryButtonState extends State<_PrimaryButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pressCtrl;
  late final Animation<double>   _scaleAnim;

  @override
  void initState() {
    super.initState();
    _pressCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 80),
      reverseDuration: const Duration(milliseconds: 160),
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.975).animate(
        CurvedAnimation(parent: _pressCtrl, curve: Curves.easeOut),);
  }

  @override
  void dispose() { _pressCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnim,
      child: GestureDetector(
        onTapDown: widget.onTap != null ? (_) => _pressCtrl.forward() : null,
        onTapUp: (_) { _pressCtrl.reverse(); widget.onTap?.call(); },
        onTapCancel: () => _pressCtrl.reverse(),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: double.infinity,
          height: 54,
          decoration: BoxDecoration(
            gradient: widget.isLoading
                ? null
                : LinearGradient(
                    colors: [
                      AppColors.primary,
                      Color.lerp(AppColors.primary, AppColors.accentPurple, 0.45)!,
                    ],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
            color: widget.isLoading ? AppColors.primary.withValues(alpha: 0.5) : null,
            borderRadius: BorderRadius.circular(15),
            boxShadow: widget.isLoading
                ? null
                : [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.32),
                      blurRadius: 20, offset: const Offset(0, 8), spreadRadius: -4,
                    ),
                  ],
          ),
          child: Center(
            child: widget.isLoading
                ? const SizedBox(
                    width: 22, height: 22,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2.5,),)
                : Row(mainAxisSize: MainAxisSize.min, children: [
                    Text(widget.label,
                        style: const TextStyle(
                          color: Colors.white, fontSize: 15,
                          fontWeight: FontWeight.w700, letterSpacing: -0.1,
                        ),),
                    const SizedBox(width: 8),
                    Icon(widget.icon, color: Colors.white.withValues(alpha: 0.85), size: 16),
                  ],),
          ),
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 200),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.expense.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: AppColors.expense.withValues(alpha: 0.20)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 1),
              child: Container(
                width: 20, height: 20,
                decoration: BoxDecoration(
                  color: AppColors.expense.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(Icons.error_outline_rounded,
                      color: AppColors.expense, size: 12,),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(message,
                  style: const TextStyle(
                    fontSize: 13, color: AppColors.expense,
                    fontWeight: FontWeight.w500, height: 1.4,
                  ),),
            ),
          ],
        ),
      ),
    );
  }
}