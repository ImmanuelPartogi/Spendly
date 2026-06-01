import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
import '../../core/theme/app_colors.dart';

const _kTourDone = 'app_tour_done';

// ─────────────────────────────────────────────────────────────────────────────
// Coach Mark Service
// ─────────────────────────────────────────────────────────────────────────────

class CoachMarkService {
  CoachMarkService._();

  static Future<bool> isTourDone() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kTourDone) ?? false;
  }

  static Future<void> markTourDone() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kTourDone, true);
  }

  static Future<void> resetTour() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kTourDone);
  }

  /// Buat dan tampilkan tour untuk DashboardScreen.
  ///
  /// Cara pakai:
  /// ```dart
  /// // Di DashboardScreen initState:
  /// WidgetsBinding.instance.addPostFrameCallback((_) async {
  ///   final done = await CoachMarkService.isTourDone();
  ///   if (!done && mounted) {
  ///     CoachMarkService.showDashboardTour(context, keys: _tourKeys);
  ///   }
  /// });
  /// ```
  static void showDashboardTour(
    BuildContext context, {
    required DashboardTourKeys keys,
  }) {
    final targets = <TargetFocus>[
      // ── Balance Card ────────────────────────────────────────────────────
      TargetFocus(
        identify: 'balance_card',
        keyTarget: keys.balanceCard,
        shape: ShapeLightFocus.RRect,
        radius: 24,
        paddingFocus: 8,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            builder: (_, __) => _CoachContent(
              icon: '💳',
              title: 'Total Saldo',
              body:
                  'Di sini kamu bisa lihat total saldo dari semua dompet yang kamu punya.',
            ),
          ),
        ],
      ),

      // ── FAB ────────────────────────────────────────────────────────────
      TargetFocus(
        identify: 'fab',
        keyTarget: keys.fab,
        shape: ShapeLightFocus.Circle,
        paddingFocus: 12,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            builder: (_, __) => _CoachContent(
              icon: '➕',
              title: 'Tambah Transaksi',
              body:
                  'Tap tombol ini untuk mencatat pengeluaran atau pemasukan baru. Hanya 3 detik!',
            ),
          ),
        ],
      ),

      // ── Insights ───────────────────────────────────────────────────────
      TargetFocus(
        identify: 'insights',
        keyTarget: keys.insights,
        shape: ShapeLightFocus.RRect,
        radius: 16,
        paddingFocus: 6,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            builder: (_, __) => _CoachContent(
              icon: '✨',
              title: 'Analisis Cerdas',
              body:
                  'Spendly menganalisis pola belanjamu dan memberikan wawasan otomatis setiap hari.',
            ),
          ),
        ],
      ),

      // ── Recent transactions ─────────────────────────────────────────────
      TargetFocus(
        identify: 'recent',
        keyTarget: keys.recentTransactions,
        shape: ShapeLightFocus.RRect,
        radius: 16,
        paddingFocus: 6,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            builder: (_, __) => _CoachContent(
              icon: '📋',
              title: 'Transaksi Terbaru',
              body:
                  'Semua transaksimu tampil di sini. Ketuk untuk lihat detail, geser untuk hapus.',
            ),
          ),
        ],
      ),
    ];

    TutorialCoachMark(
      targets: targets,
      colorShadow: Colors.black,
      opacityShadow: 0.85,
      textSkip: 'LEWATI',
      paddingFocus: 8,
      hideSkip: false,
      onFinish: () => markTourDone(),
      onSkip: () {
        markTourDone();
        return true;
      },
    ).show(context: context);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tour Keys Container
// ─────────────────────────────────────────────────────────────────────────────

/// Kumpulkan semua GlobalKey yang dibutuhkan tour dalam satu class.
class DashboardTourKeys {
  final GlobalKey balanceCard;
  final GlobalKey fab;
  final GlobalKey insights;
  final GlobalKey recentTransactions;

  DashboardTourKeys({
    GlobalKey? balanceCard,
    GlobalKey? fab,
    GlobalKey? insights,
    GlobalKey? recentTransactions,
  })  : balanceCard = balanceCard ?? GlobalKey(),
        fab = fab ?? GlobalKey(),
        insights = insights ?? GlobalKey(),
        recentTransactions = recentTransactions ?? GlobalKey();
}

// ─────────────────────────────────────────────────────────────────────────────
// Coach Content Widget
// ─────────────────────────────────────────────────────────────────────────────

class _CoachContent extends StatelessWidget {
  final String icon;
  final String title;
  final String body;

  const _CoachContent({
    required this.icon,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(icon, style: const TextStyle(fontSize: 32)),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            body,
            style: TextStyle(
              color: Colors.white.withOpacity(0.85),
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Usage Example (paste ke DashboardScreen)
// ─────────────────────────────────────────────────────────────────────────────

/*
class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});
  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  final _tourKeys = DashboardTourKeys();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final done = await CoachMarkService.isTourDone();
      if (!done && mounted) {
        CoachMarkService.showDashboardTour(context, keys: _tourKeys);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ...,
      // Tambahkan key ke widget yang ingin di-highlight:
      // BalanceCard → Key(_tourKeys.balanceCard)
      // FAB        → Key(_tourKeys.fab) di FloatingActionButton
    );
  }
}
*/