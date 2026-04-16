import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Model
// ─────────────────────────────────────────────────────────────────────────────

class MonthStats {
  final double income;
  final double expense;

  const MonthStats({required this.income, required this.expense});

  double get savings => income - expense;
}

// ─────────────────────────────────────────────────────────────────────────────
// Widget
// ─────────────────────────────────────────────────────────────────────────────

/// Bandingkan statistik keuangan bulan ini vs bulan lalu.
///
/// Menampilkan tiga metrik: Pengeluaran, Pemasukan, Tabungan —
/// masing-masing dengan delta persentase dan warna merah/hijau.
///
/// Contoh:
/// ```dart
/// MonthlyComparisonCard(
///   thisMonth: MonthStats(income: 8000000, expense: 3200000),
///   lastMonth: MonthStats(income: 7500000, expense: 2800000),
/// )
/// ```
class MonthlyComparisonCard extends ConsumerWidget {
  /// Data bulan ini (bisa di-pass langsung atau ambil dari provider).
  final MonthStats? thisMonth;

  /// Data bulan lalu.
  final MonthStats? lastMonth;

  const MonthlyComparisonCard({
    super.key,
    this.thisMonth,
    this.lastMonth,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // TODO: jika thisMonth/lastMonth null, ambil dari provider:
    // final thisMonth = ref.watch(currentMonthStatsProvider);
    // final lastMonth = ref.watch(lastMonthStatsProvider);

    final current = thisMonth ??
        const MonthStats(income: 8000000, expense: 3250000);
    final previous = lastMonth ??
        const MonthStats(income: 7500000, expense: 2800000);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          children: [
            const Icon(Icons.compare_arrows_rounded,
                size: 18, color: AppColors.primary),
            const SizedBox(width: 8),
            Text(
              'vs Bulan Lalu',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Three comparison items
        Row(
          children: [
            Expanded(
              child: _CompareItem(
                label: 'Pengeluaran',
                current: current.expense,
                previous: previous.expense,
                positiveIsGood: false, // naik = buruk
                icon: Icons.arrow_upward_rounded,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _CompareItem(
                label: 'Pemasukan',
                current: current.income,
                previous: previous.income,
                positiveIsGood: true,
                icon: Icons.arrow_downward_rounded,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _CompareItem(
                label: 'Tabungan',
                current: current.savings,
                previous: previous.savings,
                positiveIsGood: true,
                icon: Icons.savings_rounded,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Internal widgets
// ─────────────────────────────────────────────────────────────────────────────

class _CompareItem extends StatelessWidget {
  final String label;
  final double current;
  final double previous;

  /// true  → naik = hijau, turun = merah  (income / savings)
  /// false → naik = merah, turun = hijau  (expense)
  final bool positiveIsGood;
  final IconData icon;

  const _CompareItem({
    required this.label,
    required this.current,
    required this.previous,
    required this.positiveIsGood,
    required this.icon,
  });

  double get _delta {
    if (previous == 0) return 0;
    return ((current - previous) / previous) * 100;
  }

  bool get _isUp => _delta >= 0;

  Color get _color {
    final isGood = positiveIsGood ? _isUp : !_isUp;
    return isGood ? AppColors.income : AppColors.expense;
  }

  @override
  Widget build(BuildContext context) {
    final color = _color;
    final deltaAbs = _delta.abs().toStringAsFixed(0);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon
          Icon(icon, size: 16, color: color),
          const SizedBox(height: 8),

          // Current value (animated)
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: current),
            duration: const Duration(milliseconds: 700),
            curve: Curves.easeOutCubic,
            builder: (_, val, __) => Text(
              CurrencyFormatter.formatCompact(val),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(height: 2),

          // Label
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 6),

          // Delta badge
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _isUp
                    ? Icons.arrow_upward_rounded
                    : Icons.arrow_downward_rounded,
                size: 10,
                color: color,
              ),
              const SizedBox(width: 2),
              Text(
                '$deltaAbs%',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}