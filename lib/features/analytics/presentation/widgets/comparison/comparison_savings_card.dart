import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/utils/currency_formatter.dart';
import '../../screens/income_expense_comparison_screen.dart';

class ComparisonSavingsCard extends StatelessWidget {
  final List<ComparisonData> data;
  final bool isDark;

  const ComparisonSavingsCard({
    super.key,
    required this.data,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final card = isDark ? AppColors.cardDark : AppColors.card;
    final bdr = isDark ? AppColors.borderDark : AppColors.border;
    final txtPrim = isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;
    final txtSec =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;
    final div = isDark ? AppColors.dividerDark : AppColors.divider;

    final best = data.isEmpty
        ? null
        : data.reduce((a, b) => a.savings > b.savings ? a : b);
    final worst = data.isEmpty
        ? null
        : data.reduce((a, b) => a.savings < b.savings ? a : b);
    final avg = data.isEmpty
        ? 0.0
        : data.map((d) => d.savings).reduce((a, b) => a + b) / data.length;

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 20),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: bdr, width: 0.5),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Tren Tabungan',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: txtPrim,
                        letterSpacing: -0.3,),),
                const SizedBox(height: 3),
                Text('Surplus = Pemasukan − Pengeluaran',
                    style: TextStyle(fontSize: 11, color: txtSec),),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: (avg >= 0 ? AppColors.income : AppColors.expense)
                  .withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Rata-rata ${CurrencyFormatter.formatCompact(avg.abs())}',
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: avg >= 0 ? AppColors.income : AppColors.expense,),
            ),
          ),
        ],),
        const SizedBox(height: 20),
        _SavingsLineChart(data: data, isDark: isDark),
        const SizedBox(height: 16),

        if (best != null && worst != null) ...[
          Container(height: 0.5, color: div),
          const SizedBox(height: 14),
          Row(children: [
            Expanded(
              child: _PeriodStat(
                label: 'Terbaik', period: best.label,
                value: best.savings, color: AppColors.income,
                icon: Icons.emoji_events_rounded, isDark: isDark,
              ),
            ),
            Container(width: 0.5, height: 40, color: div),
            Expanded(
              child: _PeriodStat(
                label: 'Terburuk', period: worst.label,
                value: worst.savings, color: AppColors.expense,
                icon: Icons.warning_amber_rounded, isDark: isDark,
              ),
            ),
          ],),
        ],
      ],),
    );
  }
}

class _SavingsLineChart extends StatelessWidget {
  final List<ComparisonData> data;
  final bool isDark;

  const _SavingsLineChart({required this.data, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final sec = isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;
    final div = isDark ? AppColors.dividerDark : AppColors.divider;
    final spots = data.asMap().entries
        .map((e) => FlSpot(e.key.toDouble(), e.value.savings))
        .toList();
    final allVals = data.map((d) => d.savings).toList();
    final maxY = allVals.fold(0.0, (m, v) => v > m ? v : m);
    final minY = allVals.fold(0.0, (m, v) => v < m ? v : m);
    final pad = ((maxY - minY) * 0.25).abs().clamp(10000.0, double.infinity);

    return SizedBox(
      height: 130,
      child: LineChart(LineChartData(
        gridData: FlGridData(
          show: true, drawVerticalLine: false,
          getDrawingHorizontalLine: (_) =>
              FlLine(color: div, strokeWidth: 0.5, dashArray: [4, 4]),
        ),
        extraLinesData: ExtraLinesData(horizontalLines: [
          HorizontalLine(
            y: 0,
            color: isDark
                ? Colors.white.withValues(alpha: 0.18)
                : Colors.black.withValues(alpha: 0.10),
            strokeWidth: 1,
            dashArray: [5, 4],
          ),
        ],),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 24,
              getTitlesWidget: (v, _) {
                final i = v.toInt();
                if (i < 0 || i >= data.length) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(data[i].label,
                      style: TextStyle(fontSize: 9, color: sec),),
                );
              },
            ),
          ),
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        minX: 0,
        maxX: (data.length - 1).toDouble(),
        minY: minY - pad,
        maxY: maxY + pad,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            curveSmoothness: 0.35,
            color: AppColors.income,
            barWidth: 2.5,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, _, __, ___) {
                final color =
                    spot.y >= 0 ? AppColors.income : AppColors.expense;
                return FlDotCirclePainter(
                  radius: 4,
                  color: isDark ? AppColors.cardDark : AppColors.card,
                  strokeWidth: 2,
                  strokeColor: color,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.income.withValues(alpha: 0.12),
                  AppColors.income.withValues(alpha: 0.0),
                ],
              ),
              cutOffY: 0,
              applyCutOffY: true,
            ),
          ),
        ],
      ),),
    );
  }
}

class _PeriodStat extends StatelessWidget {
  final String label;
  final String period;
  final double value;
  final Color color;
  final IconData icon;
  final bool isDark;

  const _PeriodStat({
    required this.label, required this.period, required this.value,
    required this.color, required this.icon, required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final sec = isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(children: [
        Container(
          width: 28, height: 28,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 14),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label,
                style: TextStyle(
                    fontSize: 10, color: sec, fontWeight: FontWeight.w500,),),
            Text(period,
                style: TextStyle(
                    fontSize: 11, fontWeight: FontWeight.w700, color: color,),),
            Text(CurrencyFormatter.formatCompact(value.abs()),
                style: TextStyle(fontSize: 10, color: sec),),
          ],),
        ),
      ],),
    );
  }
}