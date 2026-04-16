import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
// BudgetHistoryScreen ada di file terpisah:
export '../../../budget/presentation/screens/budget_history_screen.dart';

// ── Savings Tracker ───────────────────────────────────────────────────────────

class SavingsChart extends StatefulWidget {
  final double? savingsTarget;
  final VoidCallback? onSetTarget;

  const SavingsChart({super.key, this.savingsTarget, this.onSetTarget});

  @override
  State<SavingsChart> createState() => _SavingsChartState();
}

class _SavingsChartState extends State<SavingsChart> {
  // Demo: 6 bulan tabungan kumulatif — ganti dengan provider
  final _monthlyData = <String, double>{
    'Okt': 500000,
    'Nov': 1200000,
    'Des': 800000,
    'Jan': 1800000,
    'Feb': 2400000,
    'Mar': 3100000,
  };

  @override
  Widget build(BuildContext context) {
    final entries = _monthlyData.entries.toList();
    final maxVal =
        _monthlyData.values.reduce((a, b) => a > b ? a : b);
    final target = widget.savingsTarget;
    final latestSavings = entries.last.value;
    final progress = target != null
        ? (latestSavings / target).clamp(0.0, 1.0)
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Target progress ────────────────────────────────────────────────
        if (target != null) ...[
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Target: ${CurrencyFormatter.format(target)}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: progress,
                        backgroundColor:
                            AppColors.primary.withOpacity(0.12),
                        valueColor: const AlwaysStoppedAnimation(
                            AppColors.primary),
                        minHeight: 8,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${(progress! * 100).toStringAsFixed(0)}% tercapai',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: widget.onSetTarget,
                icon: const Icon(Icons.edit_rounded,
                    size: 16, color: AppColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ] else
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: widget.onSetTarget,
              icon: const Icon(Icons.flag_rounded, size: 14),
              label: const Text('Set Target'),
              style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary),
            ),
          ),

        // ── Area chart ─────────────────────────────────────────────────────
        SizedBox(
          height: 140,
          child: LineChart(
            LineChartData(
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                getDrawingHorizontalLine: (_) => const FlLine(
                    color: AppColors.divider, strokeWidth: 1),
              ),
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (v, _) {
                      final i = v.toInt();
                      if (i < 0 || i >= entries.length) {
                        return const SizedBox.shrink();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          entries[i].key,
                          style: const TextStyle(
                              fontSize: 9,
                              color: AppColors.textHint),
                        ),
                      );
                    },
                  ),
                ),
                leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
              ),
              borderData: FlBorderData(show: false),
              minX: 0,
              maxX: (entries.length - 1).toDouble(),
              minY: 0,
              maxY: (target != null && target > maxVal
                      ? target
                      : maxVal) *
                  1.2,
              extraLinesData: target != null
                  ? ExtraLinesData(horizontalLines: [
                      HorizontalLine(
                        y: target,
                        color: AppColors.primary.withOpacity(0.5),
                        strokeWidth: 1.5,
                        dashArray: [5, 4],
                        label: HorizontalLineLabel(
                          show: true,
                          labelResolver: (_) => 'Target',
                          style: const TextStyle(
                            fontSize: 9,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ])
                  : null,
              lineBarsData: [
                LineChartBarData(
                  spots: entries
                      .asMap()
                      .entries
                      .map((e) =>
                          FlSpot(e.key.toDouble(), e.value.value))
                      .toList(),
                  isCurved: true,
                  color: AppColors.primary,
                  barWidth: 3,
                  dotData: FlDotData(
                    show: true,
                    getDotPainter: (_, __, ___, ____) =>
                        FlDotCirclePainter(
                      radius: 4,
                      color: Colors.white,
                      strokeWidth: 2,
                      strokeColor: AppColors.primary,
                    ),
                  ),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        AppColors.primary.withOpacity(0.2),
                        AppColors.primary.withOpacity(0.02),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            'Total tabungan: ${CurrencyFormatter.format(latestSavings)}',
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}