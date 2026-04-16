import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/utils/currency_formatter.dart';
import '../../screens/income_expense_comparison_screen.dart';

class ComparisonInsightPanel extends StatelessWidget {
  final List<ComparisonData> data;
  final double totalIncome;
  final double totalExpense;
  final bool isDark;

  const ComparisonInsightPanel({
    super.key,
    required this.data,
    required this.totalIncome,
    required this.totalExpense,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return const SizedBox.shrink();

    final savings = totalIncome - totalExpense;
    final rate = totalIncome > 0 ? (savings / totalIncome * 100) : 0.0;
    final avgIncome = data.map((d) => d.income).reduce((a, b) => a + b) /
        data.length;
    final avgExpense = data.map((d) => d.expense).reduce((a, b) => a + b) /
        data.length;

    // Health status
    final _HealthStatus status;
    if (rate >= 20) {
      status = _HealthStatus.sehat;
    } else if (rate >= 0) {
      status = _HealthStatus.waspada;
    } else {
      status = _HealthStatus.defisit;
    }

    // Trend: last vs second-to-last period savings
    String? trendText;
    Color? trendColor;
    if (data.length >= 2) {
      final last = data.last.savings;
      final prev = data[data.length - 2].savings;
      final diff = last - prev;
      final pct = prev != 0 ? (diff / prev.abs() * 100).abs() : 0.0;
      if (diff > 0) {
        trendText = 'Tabungan naik ${pct.toStringAsFixed(0)}% vs periode sebelumnya';
        trendColor = AppColors.income;
      } else if (diff < 0) {
        trendText = 'Tabungan turun ${pct.toStringAsFixed(0)}% vs periode sebelumnya';
        trendColor = AppColors.expense;
      } else {
        trendText = 'Tabungan stabil vs periode sebelumnya';
        trendColor = AppColors.primary;
      }
    }

    final card = isDark ? AppColors.cardDark : AppColors.card;
    final bdr = isDark ? AppColors.borderDark : AppColors.border;
    final txtPrim = isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;
    final txtSec =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;
    final div = isDark ? AppColors.dividerDark : AppColors.divider;

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 20),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: bdr, width: 0.5),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Ringkasan Keuangan',
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: txtPrim,
                letterSpacing: -0.3)),
        const SizedBox(height: 3),
        Text('Gambaran kondisi finansial kamu saat ini',
            style: TextStyle(fontSize: 11, color: txtSec)),
        const SizedBox(height: 16),

        // Health row
        Row(children: [
          _HealthBadge(status: status),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(status.title,
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: status.color,
                        letterSpacing: -0.2)),
                Text(status.subtitle,
                    style: TextStyle(fontSize: 11, color: txtSec)),
              ],
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: status.color.withOpacity(0.10),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${rate.abs().toStringAsFixed(1)}%',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: status.color),
            ),
          ),
        ]),

        const SizedBox(height: 14),
        Container(height: 0.5, color: div),
        const SizedBox(height: 14),

        // Avg per period
        Row(children: [
          Expanded(
            child: _StatItem(
              icon: Icons.south_rounded,
              color: AppColors.income,
              label: 'Rata-rata Masuk',
              value: CurrencyFormatter.formatCompact(avgIncome),
              isDark: isDark,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _StatItem(
              icon: Icons.north_rounded,
              color: AppColors.expense,
              label: 'Rata-rata Keluar',
              value: CurrencyFormatter.formatCompact(avgExpense),
              isDark: isDark,
            ),
          ),
        ]),

        if (trendText != null) ...[
          const SizedBox(height: 14),
          Container(height: 0.5, color: div),
          const SizedBox(height: 14),
          Row(children: [
            Container(
              width: 6, height: 6,
              decoration: BoxDecoration(
                  color: trendColor, shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(trendText,
                  style: TextStyle(
                      fontSize: 11.5,
                      color: trendColor,
                      fontWeight: FontWeight.w600)),
            ),
          ]),
        ],
      ]),
    );
  }
}

enum _HealthStatus {
  sehat(
    title: 'Kondisi Sehat',
    subtitle: 'Kamu berhasil menyimpan > 20% pemasukan',
    color: AppColors.income,
    icon: Icons.verified_rounded,
  ),
  waspada(
    title: 'Perlu Perhatian',
    subtitle: 'Tabungan masih positif, coba tingkatkan',
    color: AppColors.warning,
    icon: Icons.info_rounded,
  ),
  defisit(
    title: 'Kondisi Defisit',
    subtitle: 'Pengeluaran melebihi pemasukan',
    color: AppColors.expense,
    icon: Icons.warning_amber_rounded,
  );

  final String title;
  final String subtitle;
  final Color color;
  final IconData icon;

  const _HealthStatus({
    required this.title,
    required this.subtitle,
    required this.color,
    required this.icon,
  });
}

class _HealthBadge extends StatelessWidget {
  final _HealthStatus status;

  const _HealthBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44, height: 44,
      decoration: BoxDecoration(
        color: status.color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Icon(status.icon, color: status.color, size: 22),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String value;
  final bool isDark;

  const _StatItem({
    required this.icon, required this.color, required this.label,
    required this.value, required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final surf = isDark ? AppColors.surfaceDark : AppColors.surface;
    final bdr = isDark ? AppColors.borderDark : AppColors.border;
    final txtPrim = isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;
    final txtSec =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: surf,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: bdr, width: 0.5),
      ),
      child: Row(children: [
        Container(
          width: 28, height: 28,
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 13),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value,
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: color,
                      letterSpacing: -0.3)),
              Text(label,
                  style: TextStyle(fontSize: 9.5, color: txtSec)),
            ],
          ),
        ),
      ]),
    );
  }
}