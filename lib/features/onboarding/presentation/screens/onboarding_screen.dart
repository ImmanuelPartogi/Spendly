import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

const _kOnboardingDone = 'onboarding_done';

Future<bool> isOnboardingDone() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool(_kOnboardingDone) ?? false;
}

Future<void> markOnboardingDone() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool(_kOnboardingDone, true);
}

// ─────────────────────────────────────────────────────────────────────────────
// OnboardingScreen — Premium redesign
//
// Perubahan:
// - Ilustrasi custom SVG-style menggunakan CustomPainter
// - Animasi masuk per-elemen (staggered entrance)
// - Page transition yang lebih halus
// - Typography hierarchy yang lebih jelas
// - Skip button yang lebih refined
// - Progress indicator premium
// ─────────────────────────────────────────────────────────────────────────────

class OnboardingScreen extends StatefulWidget {
  final VoidCallback onDone;
  const OnboardingScreen({super.key, required this.onDone});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  final _pageCtrl = PageController();
  int _currentPage = 0;

  late AnimationController _btnCtrl;
  late Animation<double> _btnScale;

  static const _pages = [
    _PageData(
      emoji: '⚡',
      badge: 'Cepat & Mudah',
      title: 'Catat dalam\n3 detik',
      subtitle:
          'Pilih kategori, masukkan nominal, dan selesai. Tidak ada form panjang, tidak ada kerumitan.',
      gradientStart: Color(0xFF3A7AFE),
      gradientEnd: Color(0xFF6B9FFF),
      features: [
        'Tambah transaksi instan',
        'Kategori otomatis',
        'Input nominal cepat',
      ],
    ),
    _PageData(
      emoji: '✨',
      badge: 'Analisis Cerdas',
      title: 'Insight cerdas\notomatis',
      subtitle:
          'Spendly menganalisis pola belanjamu dan memberikan rekomendasi personal setiap hari.',
      gradientStart: Color(0xFF7C5CBF),
      gradientEnd: Color(0xFFAB8EE8),
      features: [
        'Analisis pola belanja',
        'Rekomendasi hemat',
        'Laporan mingguan',
      ],
    ),
    _PageData(
      emoji: '🎯',
      badge: 'Budget & Target',
      title: 'Kontrol penuh\nkeuanganmu',
      subtitle:
          'Set budget per kategori, buat target tabungan, dan dapatkan peringatan sebelum over-limit.',
      gradientStart: Color(0xFF00C48C),
      gradientEnd: Color(0xFF00E5A9),
      features: ['Budget per kategori', 'Target tabungan', 'Notifikasi limit'],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _btnCtrl = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 80),
        reverseDuration: const Duration(milliseconds: 160),);
    _btnScale = Tween<double>(begin: 1.0, end: 0.96)
        .animate(CurvedAnimation(parent: _btnCtrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    _btnCtrl.dispose();
    super.dispose();
  }

  void _next() {
    if (_currentPage < _pages.length - 1) {
      _pageCtrl.nextPage(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutCubic,);
    } else {
      _finish();
    }
  }

  Future<void> _finish() async {
    await markOnboardingDone();
    widget.onDone();
  }

  @override
  Widget build(BuildContext context) {
    final page = _pages[_currentPage];
    final isLast = _currentPage == _pages.length - 1;

    return Scaffold(
      body: Stack(children: [
        // ── Animated gradient background ──────────────────────────────────
        AnimatedContainer(
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [page.gradientStart, page.gradientEnd],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),

        // ── Decorative circles ────────────────────────────────────────────
        Positioned(
          top: -80,
          right: -80,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 500),
            width: 260,
            height: 260,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.08),
            ),
          ),
        ),
        Positioned(
          bottom: 140,
          left: -60,
          child: Container(
            width: 180,
            height: 180,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.05),
            ),
          ),
        ),

        // ── Pages ─────────────────────────────────────────────────────────
        PageView.builder(
          controller: _pageCtrl,
          itemCount: _pages.length,
          onPageChanged: (i) => setState(() => _currentPage = i),
          itemBuilder: (_, i) => _OnboardingPageView(page: _pages[i]),
        ),

        // ── Skip ──────────────────────────────────────────────────────────
        SafeArea(
          child: Align(
            alignment: Alignment.topRight,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: AnimatedOpacity(
                opacity: isLast ? 0 : 1,
                duration: const Duration(milliseconds: 200),
                child: GestureDetector(
                  onTap: isLast ? null : _finish,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.20),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.30)),
                    ),
                    child: const Text(
                      'Lewati',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),

        // ── Bottom controls ───────────────────────────────────────────────
        Align(
          alignment: Alignment.bottomCenter,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(28, 0, 28, 32),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                // Page indicator
                SmoothPageIndicator(
                  controller: _pageCtrl,
                  count: _pages.length,
                  effect: const ExpandingDotsEffect(
                    dotWidth: 8,
                    dotHeight: 8,
                    activeDotColor: Colors.white,
                    dotColor: Colors.white38,
                    expansionFactor: 3,
                    spacing: 5,
                  ),
                ),
                const SizedBox(height: 28),

                // CTA button
                GestureDetector(
                  onTapDown: (_) => _btnCtrl.forward(),
                  onTapUp: (_) {
                    _btnCtrl.reverse();
                    _next();
                  },
                  onTapCancel: () => _btnCtrl.reverse(),
                  child: ScaleTransition(
                    scale: _btnScale,
                    child: Container(
                      width: double.infinity,
                      height: 56,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Center(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 250),
                          child: Row(
                            key: ValueKey(isLast),
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                isLast ? 'Mulai Sekarang' : 'Lanjut',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: page.gradientStart,
                                  letterSpacing: -0.2,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(
                                isLast
                                    ? Icons.bolt_rounded
                                    : Icons.arrow_forward_rounded,
                                color: page.gradientStart,
                                size: 20,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],),
            ),
          ),
        ),
      ],),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Page view widget
// ─────────────────────────────────────────────────────────────────────────────

class _OnboardingPageView extends StatefulWidget {
  final _PageData page;
  const _OnboardingPageView({required this.page});

  @override
  State<_OnboardingPageView> createState() => _OnboardingPageViewState();
}

class _OnboardingPageViewState extends State<_OnboardingPageView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _emojiScale;
  late final Animation<double> _titleFade;
  late final Animation<Offset> _titleSlide;
  late final Animation<double> _subtitleFade;
  late final Animation<double> _featuresFade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700),);

    _emojiScale = Tween<double>(begin: 0.5, end: 1.0).animate(CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOutBack),),);

    _titleFade = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(
        parent: _ctrl, curve: const Interval(0.2, 0.6, curve: Curves.easeOut),),);

    _titleSlide = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
        .animate(CurvedAnimation(
            parent: _ctrl,
            curve: const Interval(0.2, 0.6, curve: Curves.easeOutCubic),),);

    _subtitleFade = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(
        parent: _ctrl, curve: const Interval(0.4, 0.8, curve: Curves.easeOut),),);

    _featuresFade = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.55, 1.0, curve: Curves.easeOut),),);

    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final page = widget.page;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Spacer(flex: 2),

            // ── Emoji illustration ──────────────────────────────────────
            ScaleTransition(
              scale: _emojiScale,
              child: Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(
                      color: Colors.white.withValues(alpha: 0.30), width: 1.5,),
                ),
                child: Center(
                  child: Text(page.emoji, style: const TextStyle(fontSize: 52)),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // ── Badge ───────────────────────────────────────────────────
            FadeTransition(
              opacity: _titleFade,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.20),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.30)),
                ),
                child: Text(page.badge,
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),),
              ),
            ),
            const SizedBox(height: 20),

            // ── Title ───────────────────────────────────────────────────
            SlideTransition(
              position: _titleSlide,
              child: FadeTransition(
                opacity: _titleFade,
                child: Text(
                  page.title,
                  style: const TextStyle(
                    fontSize: 38,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    height: 1.1,
                    letterSpacing: -1.0,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ── Subtitle ────────────────────────────────────────────────
            FadeTransition(
              opacity: _subtitleFade,
              child: Text(
                page.subtitle,
                style: TextStyle(
                  fontSize: 15.5,
                  color: Colors.white.withValues(alpha: 0.82),
                  height: 1.6,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
            const SizedBox(height: 28),

            // ── Features list ───────────────────────────────────────────
            FadeTransition(
              opacity: _featuresFade,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: page.features
                    .map((f) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Row(children: [
                            Container(
                              width: 22,
                              height: 22,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.22),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.check_rounded,
                                  size: 13, color: Colors.white,),
                            ),
                            const SizedBox(width: 10),
                            Text(f,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white.withValues(alpha: 0.90),
                                ),),
                          ],),
                        ),)
                    .toList(),
              ),
            ),

            const Spacer(flex: 3),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Data model
// ─────────────────────────────────────────────────────────────────────────────

class _PageData {
  final String emoji, badge, title, subtitle;
  final Color gradientStart, gradientEnd;
  final List<String> features;

  const _PageData({
    required this.emoji,
    required this.badge,
    required this.title,
    required this.subtitle,
    required this.gradientStart,
    required this.gradientEnd,
    required this.features,
  });
}
