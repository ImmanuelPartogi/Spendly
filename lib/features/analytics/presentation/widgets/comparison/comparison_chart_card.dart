import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/utils/currency_formatter.dart';
import '../../screens/income_expense_comparison_screen.dart';

class ComparisonChartCard extends StatelessWidget {
  final List<ComparisonData> data;
  final double maxVal;
  final bool isDark;
  final int touchedIndex;
  final ValueChanged<int> onTouch;

  const ComparisonChartCard({
    super.key,
    required this.data,
    required this.maxVal,
    required this.isDark,
    required this.touchedIndex,
    required this.onTouch,
  });

  @override
  Widget build(BuildContext context) {
    final card = isDark ? AppColors.cardDark : AppColors.card;
    final bdr = isDark ? AppColors.borderDark : AppColors.border;
    final txtPrim = isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;
    final txtSec =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;

    final touched = touchedIndex >= 0 && touchedIndex < data.length
        ? data[touchedIndex]
        : null;

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 20),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: bdr, width: 0.5),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Pemasukan vs Pengeluaran',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: txtPrim,
                      letterSpacing: -0.3,),),
              const SizedBox(height: 3),
              Text('Tap bar untuk detail periode',
                  style: TextStyle(fontSize: 11, color: txtSec),),
            ],),
          ),
          const Row(children: [
            _LegendPill(color: AppColors.income, label: 'Masuk'),
            SizedBox(width: 6),
            _LegendPill(color: AppColors.expense, label: 'Keluar'),
          ],),
        ],),

        if (touched != null) ...[
          const SizedBox(height: 14),
          _TouchHighlight(data: touched, isDark: isDark),
        ],

        const SizedBox(height: 20),

        data.isEmpty
            ? _Empty(isDark: isDark)
            : _GroupedBarChart(
                data: data,
                maxVal: maxVal,
                isDark: isDark,
                touchedIndex: touchedIndex,
                onTouch: onTouch,
              ),
      ],),
    );
  }
}

class _LegendPill extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendPill({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Container(
            width: 6, height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),),
        const SizedBox(width: 4),
        Text(label,
            style: TextStyle(
                fontSize: 10, fontWeight: FontWeight.w600, color: color,),),
      ],),
    );
  }
}

class _TouchHighlight extends StatelessWidget {
  final ComparisonData data;
  final bool isDark;

  const _TouchHighlight({required this.data, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final surf = isDark ? AppColors.surfaceDark : AppColors.surface;
    final bdr = isDark ? AppColors.borderDark : AppColors.border;
    final txtPrim = isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;
    final isPos = data.savings >= 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: surf,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: bdr, width: 0.5),
      ),
      child: Row(children: [
        Text(data.label,
            style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.w700, color: txtPrim,),),
        const SizedBox(width: 12),
        _Mini(label: 'Masuk', value: data.income, color: AppColors.income),
        const SizedBox(width: 12),
        _Mini(label: 'Keluar', value: data.expense, color: AppColors.expense),
        const SizedBox(width: 12),
        _Mini(
          label: isPos ? 'Surplus' : 'Defisit',
          value: data.savings.abs(),
          color: isPos ? AppColors.income : AppColors.expense,
          prefix: isPos ? '+' : '−',
        ),
      ],),
    );
  }
}

class _Mini extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  final String prefix;

  const _Mini({
    required this.label,
    required this.value,
    required this.color,
    this.prefix = '',
  });

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('$prefix${CurrencyFormatter.formatCompact(value)}',
          style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
              letterSpacing: -0.3,),),
      Text(label,
          style: const TextStyle(
              fontSize: 9.5, color: AppColors.textSecondary,),),
    ],);
  }
}

class _GroupedBarChart extends StatelessWidget {
  final List<ComparisonData> data;
  final double maxVal;
  final bool isDark;
  final int touchedIndex;
  final ValueChanged<int> onTouch;

  const _GroupedBarChart({
    required this.data,
    required this.maxVal,
    required this.isDark,
    required this.touchedIndex,
    required this.onTouch,
  });

  @override
  Widget build(BuildContext context) {
    final sec = isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;

    return SizedBox(
      height: 180,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxVal > 0 ? maxVal * 1.3 : 1000,
          barTouchData: BarTouchData(
            touchCallback: (event, response) {
              if (event is FlTapUpEvent || event is FlPointerExitEvent) {
                onTouch(-1);
              } else if (response?.spot != null) {
                onTouch(response!.spot!.touchedBarGroupIndex);
              }
            },
            touchTooltipData: BarTouchTooltipData(
                getTooltipItem: (_, __, ___, ____) => null,),
          ),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 26,
                getTitlesWidget: (v, _) {
                  final i = v.toInt();
                  if (i < 0 || i >= data.length) return const SizedBox.shrink();
                  final isSel = i == touchedIndex;
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(data[i].label,
                        style: TextStyle(
                            fontSize: 9,
                            fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                            color: isSel ? AppColors.primary : sec,),),
                  );
                },
              ),
            ),
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: maxVal / 3,
            getDrawingHorizontalLine: (_) => FlLine(
              color: isDark
                  ? AppColors.borderDark.withValues(alpha: 0.5)
                  : AppColors.border.withValues(alpha: 0.7),
              strokeWidth: 0.5,
              dashArray: [4, 4],
            ),
          ),
          borderData: FlBorderData(show: false),
          barGroups: data.asMap().entries.map((e) {
            final isSel = e.key == touchedIndex;
            final dim = touchedIndex >= 0 && !isSel ? 0.25 : 1.0;
            return BarChartGroupData(x: e.key, barRods: [
              BarChartRodData(
                toY: e.value.income,
                color: AppColors.income.withValues(alpha: dim),
                width: 10,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(5)),
              ),
              BarChartRodData(
                toY: e.value.expense,
                color: AppColors.expense.withValues(alpha: dim),
                width: 10,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(5)),
              ),
            ],);
          }).toList(),
        ),
        swapAnimationDuration: const Duration(milliseconds: 300),
        swapAnimationCurve: Curves.easeOutQuart,
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  final bool isDark;

  const _Empty({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 140,
      child: Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : AppColors.surface,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(Icons.bar_chart_rounded,
                color: isDark ? AppColors.textHintDark : AppColors.textHint,
                size: 22,),
          ),
          const SizedBox(height: 10),
          Text('Belum ada data untuk periode ini',
              style: TextStyle(
                  fontSize: 12,
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondary,),),
        ],),
      ),
    );
  }
}