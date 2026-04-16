import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/auth_service_firebase.dart';
import '../../../../core/services/sync_service.dart';
import '../../domain/services/auth_service.dart';

// ── Auth step ─────────────────────────────────────────────────────────────────
//
// email          → user input email, sistem cek exist + cek PIN status
// pin            → user punya PIN aktif → tampilkan numpad PIN
// passwordFallback → tidak ada PIN / forgot PIN → masukkan password biasa
// register       → email belum terdaftar → form registrasi
//
enum _AuthStep { email, pin, passwordFallback, register }

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

  _AuthStep _step   = _AuthStep.email;
  bool _isLoading   = false;
  bool _obscurePass = true;
  bool _obscureConf = true;
  String? _errorMsg;
  String? _checkedEmail;

  // ── PIN step state ────────────────────────────────────────────────────────
  String  _pinInput   = '';         // digit yang sudah dimasukkan
  String? _pinHash;                 // hash dari Firestore pin_lookup
  bool    _pinShaking = false;
  static const int _pinLength = 6;

  late final AnimationController _entranceCtrl;
  late final Animation<double>   _entranceFade;
  late final Animation<Offset>   _entranceSlide;

  late final AnimationController _logoCtrl;
  late final Animation<double>   _logoScale;
  late final Animation<double>   _logoFade;

  late final AnimationController _stepCtrl;
  late final Animation<double>   _stepFade;
  late final Animation<Offset>   _stepSlide;

  late final AnimationController _shakeCtrl;
  late final Animation<double>   _shakeAnim;

  late final List<AnimationController> _dotCtrls;
  late final List<Animation<double>>   _dotScales;

  @override
  void initState() {
    super.initState();

    _entranceCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
    _entranceFade  = CurvedAnimation(
        parent: _entranceCtrl,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOut));
    _entranceSlide = Tween<Offset>(
        begin: const Offset(0, 0.05), end: Offset.zero)
        .animate(CurvedAnimation(
            parent: _entranceCtrl,
            curve: const Interval(0.0, 0.7, curve: Curves.easeOutCubic)));

    _logoCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _logoScale = Tween<double>(begin: 0.7, end: 1.0).animate(
        CurvedAnimation(parent: _logoCtrl, curve: Curves.easeOutBack));
    _logoFade  = CurvedAnimation(parent: _logoCtrl, curve: Curves.easeOut);

    _stepCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 280));
    _stepFade  = CurvedAnimation(parent: _stepCtrl, curve: Curves.easeOut);
    _stepSlide = Tween<Offset>(
        begin: const Offset(0.03, 0), end: Offset.zero)
        .animate(CurvedAnimation(
            parent: _stepCtrl, curve: Curves.easeOutCubic));

    _shakeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 480));
    _shakeAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0,   end: -10.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -10.0, end:  10.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin:  10.0, end:  -6.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin:  -6.0, end:   6.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin:   6.0, end:   0.0), weight: 1),
    ]).animate(CurvedAnimation(parent: _shakeCtrl, curve: Curves.easeInOut));

    _dotCtrls = List.generate(
      _pinLength,
      (_) => AnimationController(
          vsync: this, duration: const Duration(milliseconds: 200)),
    );
    _dotScales = List.generate(_pinLength, (i) =>
        Tween<double>(begin: 0.4, end: 1.0).animate(
            CurvedAnimation(parent: _dotCtrls[i], curve: Curves.easeOutBack)));

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
    _shakeCtrl.dispose();
    for (final c in _dotCtrls) c.dispose();
    super.dispose();
  }

  Future<void> _transitionTo(_AuthStep step) async {
    await _stepCtrl.reverse();
    if (mounted) {
      setState(() {
        _step     = step;
        _errorMsg = null;
        // Reset PIN state setiap kali berpindah step
        if (step != _AuthStep.pin) {
          _pinInput = '';
          _pinHash  = null;
          for (final c in _dotCtrls) c.reverse();
        }
      });
    }
    _stepCtrl.forward();
  }

  // ── Email exist check ─────────────────────────────────────────────────────

  Future<bool> _checkEmailExists(String email) async {
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email, password: '___spendly_check___');
      return true;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') return false;
      if (e.code == 'wrong-password' ||
          e.code == 'invalid-credential' ||
          e.code == 'invalid-login-credentials') return true;
      rethrow;
    }
  }

  // ── Step: email → cek exist → cek PIN ────────────────────────────────────
  //
  // Setelah email dikonfirmasi exist, cek pin_lookup di Firestore.
  // Jika pinEnabled: true → tampilkan PIN step.
  // Jika tidak          → tampilkan password step.
  //
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
      final exists = await _checkEmailExists(email);
      if (!mounted) return;

      if (!exists) {
        setState(() =>
            _errorMsg = 'Akun tidak ditemukan. Silakan daftar terlebih dahulu.');
        return;
      }

      _checkedEmail = email;

      // Cek apakah email ini punya PIN aktif di Firestore
      final pinData = await SyncService.checkPinByEmail(email);

      if (!mounted) return;

      if (pinData != null &&
          pinData['pinEnabled'] == true &&
          (pinData['pinHash'] as String?)?.isNotEmpty == true) {
        // Ada PIN → tampilkan PIN step
        _pinHash = pinData['pinHash'] as String;
        await _transitionTo(_AuthStep.pin);
      } else {
        // Tidak ada PIN → tampilkan password step
        await _transitionTo(_AuthStep.passwordFallback);
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) setState(() => _errorMsg = _friendlyError(e.code));
    } catch (_) {
      if (mounted) {
        setState(() => _errorMsg = 'Terjadi kesalahan. Periksa koneksi internet.');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Step: PIN input ───────────────────────────────────────────────────────

  Future<void> _onPinKey(String key) async {
    if (_isLoading) return;

    if (key == 'del') {
      if (_pinInput.isNotEmpty) {
        _dotCtrls[_pinInput.length - 1].reverse();
        HapticFeedback.lightImpact();
        setState(() {
          _pinInput = _pinInput.substring(0, _pinInput.length - 1);
          _errorMsg = null;
        });
      }
      return;
    }

    if (_pinInput.length >= _pinLength) return;

    HapticFeedback.lightImpact();
    _dotCtrls[_pinInput.length].forward(from: 0);
    final newPin = _pinInput + key;
    setState(() => _pinInput = newPin);

    if (newPin.length < _pinLength) return;

    // PIN penuh → verifikasi
    await Future.delayed(const Duration(milliseconds: 80));
    await _verifyLoginPin(newPin);
  }

  // ── Verifikasi PIN → Firebase Auth ────────────────────────────────────────
  //
  // Alur:
  //   1. Hash PIN yang dimasukkan, bandingkan dengan _pinHash dari Firestore
  //   2. Jika cocok → coba ambil cached credentials → Firebase sign-in
  //   3. Jika cached creds tidak ada → fallback ke password step
  //   4. Jika PIN salah → shake + reset
  //
  Future<void> _verifyLoginPin(String pin) async {
    final email = _checkedEmail!;
    final inputHash = AuthService.hashPin(pin, email);

    if (inputHash != _pinHash) {
      // PIN salah
      HapticFeedback.vibrate();
      await _shakeCtrl.forward(from: 0);
      if (mounted) {
        setState(() {
          _pinInput = '';
          _errorMsg = 'PIN salah, coba lagi';
        });
        for (final c in _dotCtrls) c.reverse();
      }
      return;
    }

    // PIN benar → coba Firebase sign-in dengan cached credentials
    setState(() { _isLoading = true; _errorMsg = null; });
    try {
      final creds = await AuthService.getCachedCredentials();

      if (creds != null) {
        // Ada cached creds → sign in otomatis
        await FirebaseAuthService.signInWithEmail(creds.email, creds.password);
        // AppGate akan otomatis navigasi ke MainNavigation setelah auth state berubah
      } else {
        // Tidak ada cached creds → minta password sebagai fallback
        if (mounted) {
          setState(() {
            _pinInput = '';
            _errorMsg = null;
          });
          for (final c in _dotCtrls) c.reverse();
          await _transitionTo(_AuthStep.passwordFallback);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Row(children: [
                Container(
                  width: 24, height: 24,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.info_outline_rounded,
                    color: Colors.white, size: 14),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Silakan masukkan password untuk pertama kali di perangkat ini',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                ),
              ]),
              backgroundColor: AppColors.primary,
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.all(16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              duration: const Duration(seconds: 4),
              elevation: 0,
            ));
          }
        }
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        setState(() {
          _pinInput = '';
          _errorMsg = _friendlyError(e.code);
        });
        for (final c in _dotCtrls) c.reverse();
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _pinInput = '';
          _errorMsg = 'Terjadi kesalahan. Coba lagi.';
        });
        for (final c in _dotCtrls) c.reverse();
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── "Lupa PIN?" dari login PIN step ──────────────────────────────────────
  //
  // Tidak perlu sign out — user belum login.
  // Cukup pindah ke password step.
  //
  Future<void> _onForgotPinInLogin() async {
    setState(() {
      _pinInput = '';
      _pinHash  = null;
      _errorMsg = null;
    });
    for (final c in _dotCtrls) c.reverse();
    await _transitionTo(_AuthStep.passwordFallback);
  }

  // ── Step: password ────────────────────────────────────────────────────────
  //
  // Setelah berhasil login dengan password, cache credentials ke secure storage
  // agar login berikutnya bisa memakai PIN tanpa password lagi.
  //
  Future<void> _loginWithPassword() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() { _isLoading = true; _errorMsg = null; });
    try {
      await FirebaseAuthService.signInWithEmail(
          _checkedEmail!, _passCtrl.text);

      // Cache credentials untuk PIN login di masa mendatang
      await AuthService.cacheCredentials(_checkedEmail!, _passCtrl.text);
    } on FirebaseAuthException catch (e) {
      if (mounted) setState(() => _errorMsg = _friendlyError(e.code));
    } catch (_) {
      if (mounted) setState(() => _errorMsg = 'Terjadi kesalahan. Coba lagi.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Step: register ────────────────────────────────────────────────────────

  Future<void> _register() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() { _isLoading = true; _errorMsg = null; });
    try {
      await AuthService.setPinSetupPending(true);
      final email    = _emailCtrl.text.trim();
      final password = _passCtrl.text;
      await FirebaseAuthService.registerWithEmail(email, password);

      // Cache credentials langsung setelah register
      await AuthService.cacheCredentials(email, password);
    } on FirebaseAuthException catch (e) {
      await AuthService.setPinSetupPending(false);
      if (mounted) setState(() => _errorMsg = _friendlyError(e.code));
    } catch (_) {
      await AuthService.setPinSetupPending(false);
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
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                  Icons.check_rounded, color: Colors.white, size: 14),
            ),
            const SizedBox(width: 10),
            Text('Link reset dikirim ke $email',
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w500)),
          ]),
          backgroundColor: AppColors.income,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 0,
        ));
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

                          // Back button
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
                                      key: ValueKey('empty')),
                            ),
                          ),

                          const SizedBox(height: 12),

                          // Logo
                          ScaleTransition(
                            scale: _logoScale,
                            child: FadeTransition(
                              opacity: _logoFade,
                              child: _BrandLogo(isDark: isDark),
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Title
                          _TitleBlock(
                            isDark: isDark,
                            step: _step,
                            email: _checkedEmail,
                          ),

                          const SizedBox(height: 32),

                          // Form content
                          FadeTransition(
                            opacity: _stepFade,
                            child: SlideTransition(
                              position: _stepSlide,
                              child: _step == _AuthStep.pin
                                  ? _buildPinStep(isDark: isDark)
                                  : _FormCard(
                                      isDark: isDark,
                                      child: Form(
                                        key: _formKey,
                                        child: _buildStepContent(
                                            isDark: isDark),
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
      ]),
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
      case _AuthStep.pin:
        return const SizedBox.shrink(); // handled separately
    }
  }

  // ── PIN Step UI ───────────────────────────────────────────────────────────

  Widget _buildPinStep({required bool isDark}) {
    final txtSec = isDark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondary;

    return Column(
      children: [
        // Email chip
        _EmailChip(
            email: _checkedEmail ?? _emailCtrl.text, isDark: isDark),
        const SizedBox(height: 28),

        // PIN dots
        AnimatedBuilder(
          animation: _shakeAnim,
          builder: (_, child) => Transform.translate(
              offset: Offset(_shakeAnim.value, 0), child: child),
          child: _LoginPinDots(
            filledCount: _pinInput.length,
            pinLength:   _pinLength,
            hasError:    _errorMsg != null,
            dotScales:   _dotScales,
            isDark:      isDark,
          ),
        ),

        // Error
        SizedBox(
          height: 44,
          child: Center(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: _errorMsg != null
                  ? _PinErrorRow(
                      key: ValueKey(_errorMsg),
                      message: _errorMsg!)
                  : const SizedBox.shrink(key: ValueKey('none')),
            ),
          ),
        ),

        const SizedBox(height: 8),

        // Numpad
        _LoginNumpad(onKey: _onPinKey, isDark: isDark, isLoading: _isLoading),

        const SizedBox(height: 24),

        // Lupa PIN
        GestureDetector(
          onTap: _isLoading ? null : _onForgotPinInLogin,
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.primary.withOpacity(0.10)
                  : AppColors.primary.withOpacity(0.07),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: AppColors.primary.withOpacity(0.18)),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.lock_reset_rounded,
                  size: 13,
                  color: AppColors.primary.withOpacity(0.8)),
              const SizedBox(width: 6),
              Text(
                'Lupa PIN? Gunakan password',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.1,
                ),
              ),
            ]),
          ),
        ),
      ],
    );
  }

  // ── Email Step ────────────────────────────────────────────────────────────

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
    ]);
  }

  // ── Password Step ─────────────────────────────────────────────────────────

  Widget _buildPasswordStep({required bool isDark}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _EmailChip(
            email: _checkedEmail ?? _emailCtrl.text, isDark: isDark),
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
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
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

  // ── Register Step ─────────────────────────────────────────────────────────

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
    ]);
  }

  Widget _buildFooter(bool isDark) {
    if (_step != _AuthStep.email) return const SizedBox.shrink();
    final txtSec =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;

    return Center(
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Text('Belum punya akun?  ',
            style: TextStyle(
                fontSize: 14,
                color: txtSec,
                fontWeight: FontWeight.w400)),
        GestureDetector(
          onTap: () {
            _passCtrl.clear();
            _confirmCtrl.clear();
            _transitionTo(_AuthStep.register);
          },
          child: Text(
            'Daftar sekarang',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2,
            ),
          ),
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PIN step sub-widgets
// ─────────────────────────────────────────────────────────────────────────────

class _LoginPinDots extends StatelessWidget {
  final int filledCount, pinLength;
  final bool hasError, isDark;
  final List<Animation<double>> dotScales;

  const _LoginPinDots({
    required this.filledCount,
    required this.pinLength,
    required this.hasError,
    required this.dotScales,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final emptyColor  = isDark ? AppColors.surfaceDark : Colors.white;
    final emptyBorder =
        isDark ? AppColors.borderDark : const Color(0xFFDDE2F0);
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
                    ? [BoxShadow(
                        color: filledColor.withOpacity(0.38),
                        blurRadius: 10, spreadRadius: -1)]
                    : [BoxShadow(
                        color:
                            Colors.black.withOpacity(isDark ? 0.20 : 0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 1))],
              ),
            ),
          ),
        );
      }),
    );
  }
}

class _PinErrorRow extends StatelessWidget {
  final String message;
  const _PinErrorRow({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.expense.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border:
            Border.all(color: AppColors.expense.withOpacity(0.22)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 16, height: 16,
          decoration: BoxDecoration(
            color: AppColors.expense.withOpacity(0.12),
            shape: BoxShape.circle,
          ),
          child: const Center(
            child: Icon(Icons.close_rounded,
                size: 10, color: AppColors.expense),
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
      ]),
    );
  }
}

class _LoginNumpad extends StatelessWidget {
  final Future<void> Function(String) onKey;
  final bool isDark, isLoading;

  const _LoginNumpad({
    required this.onKey,
    required this.isDark,
    required this.isLoading,
  });

  static const _rows = [
    ['1', '2', '3'],
    ['4', '5', '6'],
    ['7', '8', '9'],
    ['',  '0', 'del'],
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
                isLoading: isLoading,
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
    required this.value,
    required this.isDark,
    required this.isLoading,
    required this.onTap,
  });

  @override
  State<_NumKey> createState() => _NumKeyState();
}

class _NumKeyState extends State<_NumKey>
    with SingleTickerProviderStateMixin {
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
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.86).animate(
        CurvedAnimation(parent: _pressCtrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _pressCtrl.dispose();
    super.dispose();
  }

  bool get _isSpecial => widget.value == 'del';

  @override
  Widget build(BuildContext context) {
    final txtPrim =
        widget.isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;
    final txtSec  = widget.isDark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondary;
    final keyColor = widget.isDark ? AppColors.surfaceDark : Colors.white;
    final bdrColor = widget.isDark
        ? AppColors.borderDark
        : const Color(0xFFE8ECFF);

    Widget keyChild;
    if (widget.value == 'del') {
      keyChild = widget.isLoading
          ? SizedBox(
              width: 18, height: 18,
              child: CircularProgressIndicator(
                  color: txtSec, strokeWidth: 2))
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
      onTapUp:   (_) { _pressCtrl.reverse(); widget.onTap(widget.value); },
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
                      color: Colors.black
                          .withOpacity(widget.isDark ? 0.22 : 0.055),
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

// ─────────────────────────────────────────────────────────────────────────────
// Shared sub-widgets (sama seperti sebelumnya)
// ─────────────────────────────────────────────────────────────────────────────

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
              color: AppColors.primary.withOpacity(0.30),
              blurRadius: 16,
              offset: const Offset(0, 6),
              spreadRadius: -2,
            ),
          ],
        ),
        child: const Icon(Icons.bolt_rounded, color: Colors.white, size: 26),
      ),
      const SizedBox(width: 12),
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Spendly',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: isDark
                  ? AppColors.textPrimaryDark
                  : AppColors.textPrimary,
              letterSpacing: -0.5,
            ),
          ),
          Text(
            'Kelola keuanganmu',
            style: TextStyle(
              fontSize: 12,
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondary,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    ]);
  }
}

class _TitleBlock extends StatelessWidget {
  final bool isDark;
  final _AuthStep step;
  final String? email;

  const _TitleBlock(
      {required this.isDark, required this.step, this.email});

  @override
  Widget build(BuildContext context) {
    final txtPrim =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;
    final txtSec  =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;

    final title = switch (step) {
      _AuthStep.email            => 'Selamat\nDatang Kembali',
      _AuthStep.register         => 'Buat Akun\nBaru',
      _AuthStep.passwordFallback => 'Masukkan\nPassword',
      _AuthStep.pin              => 'Masukkan\nPIN Kamu',
    };
    final subtitle = switch (step) {
      _AuthStep.email            =>
          'Masuk untuk melanjutkan pengelolaan keuanganmu.',
      _AuthStep.register         =>
          'Daftar gratis dan mulai lacak pengeluaranmu hari ini.',
      _AuthStep.passwordFallback =>
          'Verifikasi identitasmu untuk melanjutkan.',
      _AuthStep.pin              =>
          'Masukkan 6 digit PIN untuk membuka Spendly.',
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 280),
          transitionBuilder: (child, anim) => FadeTransition(
            opacity: anim,
            child: SlideTransition(
              position: Tween<Offset>(
                      begin: const Offset(0, 0.06), end: Offset.zero)
                  .animate(anim),
              child: child,
            ),
          ),
          child: Text(
            title,
            key: ValueKey(step),
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              color: txtPrim,
              letterSpacing: -1.2,
              height: 1.1,
            ),
          ),
        ),
        const SizedBox(height: 8),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 280),
          child: Text(
            subtitle,
            key: ValueKey('sub_$step'),
            style: TextStyle(
              fontSize: 14.5,
              color: txtSec,
              height: 1.5,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ],
    );
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
          color: isDark
              ? AppColors.borderDark
              : const Color(0xFFE8ECFF),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.30)
                : AppColors.primary.withOpacity(0.06),
            blurRadius: 40,
            offset: const Offset(0, 12),
            spreadRadius: -4,
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
      padding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.primary.withOpacity(0.10)
            : AppColors.primary.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: AppColors.primary.withOpacity(0.18)),
      ),
      child: Row(children: [
        Container(
          width: 32, height: 32,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.alternate_email_rounded,
              size: 15, color: AppColors.primary),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Masuk sebagai',
                style: TextStyle(
                  fontSize: 10.5,
                  color: AppColors.primary.withOpacity(0.7),
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                email,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
        ),
      ]),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool isDark;
  const _InfoChip(
      {required this.icon, required this.text, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final color =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 13, color: color.withOpacity(0.6)),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: color.withOpacity(0.6),
              height: 1.5,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ],
    );
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
            color: isDark
                ? AppColors.borderDark
                : const Color(0xFFE8ECFF),
          ),
          boxShadow: [
            BoxShadow(
              color:
                  Colors.black.withOpacity(isDark ? 0.2 : 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          Icons.arrow_back_ios_new_rounded,
          size: 14,
          color: isDark
              ? AppColors.textSecondaryDark
              : AppColors.textSecondary,
        ),
      ),
    );
  }
}

class _BackgroundDecoration extends StatelessWidget {
  final bool isDark;
  final Size size;
  const _BackgroundDecoration(
      {required this.isDark, required this.size});

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
                AppColors.primary
                    .withOpacity(isDark ? 0.13 : 0.10),
                Colors.transparent,
              ]),
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
                AppColors.accentPurple
                    .withOpacity(isDark ? 0.09 : 0.07),
                Colors.transparent,
              ]),
            ),
          ),
        ),
        if (!isDark)
          Positioned.fill(
              child: CustomPaint(painter: _DotGridPainter())),
      ]),
    );
  }
}

class _DotGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primary.withOpacity(0.04)
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

// ─────────────────────────────────────────────────────────────────────────────
// Pro Form Field
// ─────────────────────────────────────────────────────────────────────────────

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
  final _focus = FocusNode();
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _focus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isFocused = _focus.hasFocus;
    final txtPrim   = widget.isDark
        ? AppColors.textPrimaryDark
        : AppColors.textPrimary;
    final txtHint   =
        widget.isDark ? AppColors.textHintDark : AppColors.textHint;
    final txtSec    = widget.isDark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondary;
    final surfColor = widget.isDark
        ? AppColors.surfaceDark
        : const Color(0xFFF8F9FF);
    final bdrColor  =
        widget.isDark ? AppColors.borderDark : const Color(0xFFE8ECFF);

    final borderColor = isFocused
        ? AppColors.primary.withOpacity(0.55)
        : _hasError
            ? AppColors.expense.withOpacity(0.55)
            : bdrColor;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 1, bottom: 7),
          child: Text(
            widget.label,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: isFocused ? AppColors.primary : txtSec,
              letterSpacing: 0.1,
            ),
          ),
        ),
        AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          decoration: BoxDecoration(
            color: isFocused
                ? (widget.isDark ? AppColors.surfaceDark : Colors.white)
                : surfColor,
            borderRadius: BorderRadius.circular(14),
            border:
                Border.all(color: borderColor, width: isFocused ? 1.5 : 1),
            boxShadow: isFocused
                ? [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.08),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    )
                  ]
                : null,
          ),
          child: TextFormField(
            controller: widget.controller,
            focusNode: _focus,
            obscureText: widget.obscureText,
            keyboardType: widget.keyboardType,
            style: TextStyle(
              color: txtPrim,
              fontSize: 14.5,
              fontWeight: FontWeight.w500,
              letterSpacing: -0.1,
            ),
            decoration: InputDecoration(
              hintText: widget.hint,
              hintStyle: TextStyle(
                  color: txtHint,
                  fontSize: 14,
                  fontWeight: FontWeight.w400),
              prefixIcon: Padding(
                padding: const EdgeInsets.only(left: 4, right: 2),
                child: Icon(widget.icon,
                    size: 17,
                    color: isFocused
                        ? AppColors.primary
                        : txtSec.withOpacity(0.6)),
              ),
              suffixIcon: widget.onToggleObscure != null
                  ? IconButton(
                      padding: EdgeInsets.zero,
                      icon: Icon(
                        widget.obscureText
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        size: 17,
                        color: txtSec.withOpacity(0.6),
                      ),
                      onPressed: widget.onToggleObscure)
                  : null,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              errorBorder: InputBorder.none,
              focusedErrorBorder: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 15),
              fillColor: Colors.transparent,
              filled: false,
              isDense: true,
              errorStyle:
                  const TextStyle(height: 0, fontSize: 0),
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
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Primary Button
// ─────────────────────────────────────────────────────────────────────────────

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
        CurvedAnimation(parent: _pressCtrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _pressCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnim,
      child: GestureDetector(
        onTapDown:
            widget.onTap != null ? (_) => _pressCtrl.forward() : null,
        onTapUp: (_) {
          _pressCtrl.reverse();
          widget.onTap?.call();
        },
        onTapCancel: () => _pressCtrl.reverse(),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: double.infinity, height: 54,
          decoration: BoxDecoration(
            gradient: widget.isLoading
                ? null
                : LinearGradient(
                    colors: [
                      AppColors.primary,
                      Color.lerp(AppColors.primary,
                          AppColors.accentPurple, 0.45)!,
                    ],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
            color: widget.isLoading
                ? AppColors.primary.withOpacity(0.5)
                : null,
            borderRadius: BorderRadius.circular(15),
            boxShadow: widget.isLoading
                ? null
                : [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.32),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                      spreadRadius: -4,
                    ),
                  ],
          ),
          child: Center(
            child: widget.isLoading
                ? const SizedBox(
                    width: 22, height: 22,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2.5))
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.1,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(widget.icon,
                          color: Colors.white.withOpacity(0.85),
                          size: 16),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Error Banner
// ─────────────────────────────────────────────────────────────────────────────

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 200),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
            horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.expense.withOpacity(0.06),
          borderRadius: BorderRadius.circular(13),
          border: Border.all(
              color: AppColors.expense.withOpacity(0.20)),
        ),
        child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 1),
                child: Container(
                  width: 20, height: 20,
                  decoration: BoxDecoration(
                    color: AppColors.expense.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(Icons.error_outline_rounded,
                        color: AppColors.expense, size: 12),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.expense,
                    fontWeight: FontWeight.w500,
                    height: 1.4,
                  ),
                ),
              ),
            ]),
      ),
    );
  }
}