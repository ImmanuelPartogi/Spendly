import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/utils/category_utils.dart';
import '../../../../../core/utils/currency_formatter.dart';

class AnalyticsInsightCard extends StatelessWidget {
  final Map<String, double> categories;
  final Map<int, double> weekday;
  final double expense;
  final Map<String, double> daily;
  final bool isDark;

  const AnalyticsInsightCard({
    super.key,
    required this.categories,
    required this.weekday,
    required this.expense,
    required this.daily,
    required this.isDark,
  });

  static const _dayNames = [
    'Senin','Selasa','Rabu','Kamis','Jumat','Sabtu','Minggu'
  ];

  @override
  Widget build(BuildContext context) {
    final card = isDark ? AppColors.cardDark : AppColors.card;
    final bdr = isDark ? AppColors.borderDark : AppColors.border;
    final txtPrim = isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;
    final txtSec =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;
    final div = isDark ? AppColors.dividerDark : AppColors.divider;

    // Derived insights
    final topCat = categories.entries.isEmpty
        ? null
        : categories.entries.reduce((a, b) => a.value > b.value ? a : b);

    final activeDays = daily.values.where((v) => v > 0).length;
    final avgDaily = activeDays > 0 ? expense / activeDays : 0.0;

    final peakWeekday = weekday.entries.isEmpty
        ? null
        : weekday.entries.reduce((a, b) => a.value > b.value ? a : b);

    final insights = <_InsightData>[];

    if (topCat != null && expense > 0) {
      final pct = (topCat.value / expense * 100).toStringAsFixed(0);
      insights.add(_InsightData(
        icon: CategoryUtils.getIcon(topCat.key),
        color: CategoryUtils.getColor(topCat.key),
        title: 'Kategori Terbesar',
        subtitle: '${topCat.key} · $pct% dari total',
        value: CurrencyFormatter.formatCompact(topCat.value),
      ));
    }

    if (avgDaily > 0) {
      insights.add(_InsightData(
        icon: Icons.today_rounded,
        color: AppColors.expense,
        title: 'Rata-rata Harian',
        subtitle: 'Dari $activeDays hari dengan transaksi',
        value: CurrencyFormatter.formatCompact(avgDaily),
      ));
    }

    if (peakWeekday != null && peakWeekday.value > 0) {
      insights.add(_InsightData(
        icon: Icons.bar_chart_rounded,
        color: AppColors.primary,
        title: 'Hari Paling Boros',
        subtitle: 'Pengeluaran tertinggi dalam seminggu',
        value: _dayNames[(peakWeekday.key - 1).clamp(0, 6)],
      ));
    }

    if (insights.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 6),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: bdr, width: 0.5),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Insight Minggu Ini',
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: txtPrim,
                letterSpacing: -0.3)),
        const SizedBox(height: 3),
        Text('Ringkasan pola pengeluaran kamu',
            style: TextStyle(fontSize: 11, color: txtSec)),
        const SizedBox(height: 16),
        ...insights.asMap().entries.map((e) {
          final d = e.value;
          final isLast = e.key == insights.length - 1;
          return Column(children: [
            _InsightRow(data: d, isDark: isDark),
            if (!isLast) ...[
              const SizedBox(height: 12),
              Container(height: 0.5, color: div),
              const SizedBox(height: 12),
            ] else
              const SizedBox(height: 14),
          ]);
        }),
      ]),
    );
  }
}

class _InsightData {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final String value;

  const _InsightData({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.value,
  });
}

class _InsightRow extends StatelessWidget {
  final _InsightData data;
  final bool isDark;

  const _InsightRow({required this.data, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final txtPrim = isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;
    final txtSec =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;

    return Row(children: [
      Container(
        width: 38, height: 38,
        decoration: BoxDecoration(
          color: data.color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(11),
        ),
        child: Icon(data.icon, color: data.color, size: 18),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(data.title,
              style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: txtPrim,
                  letterSpacing: -0.1)),
          const SizedBox(height: 2),
          Text(data.subtitle,
              style: TextStyle(fontSize: 10.5, color: txtSec)),
        ]),
      ),
      Text(data.value,
          style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: data.color,
              letterSpacing: -0.3)),
    ]);
  }
}