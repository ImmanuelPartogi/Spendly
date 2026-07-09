import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';

/// Line chart dua garis: income vs expense per hari (7 hari terakhir).
class CashflowChart extends ConsumerStatefulWidget {
  const CashflowChart({super.key});

  @override
  ConsumerState<CashflowChart> createState() => _CashflowChartState();
}

class _CashflowChartState extends ConsumerState<CashflowChart> {
  int? _touchedX;

  // Demo data — ganti dengan provider
  final _incomeData = <int, double>{
    0: 0,
    1: 500000,
    2: 0,
    3: 2500000,
    4: 0,
    5: 300000,
    6: 0,
  };
  final _expenseData = <int, double>{
    0: 120000,
    1: 350000,
    2: 80000,
    3: 450000,
    4: 210000,
    5: 180000,
    6: 95000,
  };

  @override
  Widget build(BuildContext context) {
    final labels = _last7DayLabels();
    final maxY = [
      ..._incomeData.values,
      ..._expenseData.values,
    ].fold(0.0, (a, b) => a > b ? a : b);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Touch tooltip ─────────────────────────────────────────────────
        if (_touchedX != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                _TooltipBadge(
                  label: 'Pemasukan',
                  value: _incomeData[_touchedX!] ?? 0,
                  color: AppColors.income,
                ),
                const SizedBox(width: 12),
                _TooltipBadge(
                  label: 'Pengeluaran',
                  value: _expenseData[_touchedX!] ?? 0,
                  color: AppColors.expense,
                ),
              ],
            ),
          ),

        // ── Chart ─────────────────────────────────────────────────────────
        SizedBox(
          height: 160,
          child: LineChart(
            LineChartData(
              lineTouchData: LineTouchData(
                touchCallback: (event, response) {
                  if (event.isInterestedForInteractions &&
                      response?.lineBarSpots?.isNotEmpty == true) {
                    setState(() {
                      _touchedX = response!
                          .lineBarSpots!.first.x
                          .toInt();
                    });
                  } else {
                    setState(() => _touchedX = null);
                  }
                },
                handleBuiltInTouches: false,
                touchSpotThreshold: 20,
              ),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                getDrawingHorizontalLine: (_) =>
                    const FlLine(color: AppColors.divider, strokeWidth: 1),
              ),
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (v, _) {
                      final i = v.toInt();
                      if (i < 0 || i >= labels.length) {
                        return const SizedBox.shrink();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          labels[i],
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppColors.textHint,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),),
                topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),),
                rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),),
              ),
              borderData: FlBorderData(show: false),
              minX: 0,
              maxX: 6,
              minY: 0,
              maxY: maxY * 1.3,
              lineBarsData: [
                // Income line
                _buildLine(
                  data: _incomeData,
                  color: AppColors.income,
                ),
                // Expense line
                _buildLine(
                  data: _expenseData,
                  color: AppColors.expense,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // ── Legend ────────────────────────────────────────────────────────
        const Row(
          children: [
            _LegendDot(color: AppColors.income, label: 'Pemasukan'),
            SizedBox(width: 16),
            _LegendDot(color: AppColors.expense, label: 'Pengeluaran'),
          ],
        ),
      ],
    );
  }

  LineChartBarData _buildLine({
    required Map<int, double> data,
    required Color color,
  }) {
    final spots = List.generate(
      7,
      (i) => FlSpot(i.toDouble(), data[i] ?? 0),
    );
    return LineChartBarData(
      spots: spots,
      isCurved: true,
      color: color,
      barWidth: 2.5,
      isStrokeCapRound: true,
      dotData: FlDotData(
        show: true,
        getDotPainter: (spot, _, __, ___) => FlDotCirclePainter(
          radius: 3,
          color: Colors.white,
          strokeWidth: 2,
          strokeColor: color,
        ),
      ),
      belowBarData: BarAreaData(
        show: true,
        color: color.withValues(alpha: 0.06),
      ),
    );
  }

  List<String> _last7DayLabels() {
    final now = DateTime.now();
    return List.generate(7, (i) {
      final d = now.subtract(Duration(days: 6 - i));
      return '${d.day}/${d.month}';
    });
  }
}

class _TooltipBadge extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  const _TooltipBadge({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 10, color: color, fontWeight: FontWeight.w500,),),
          Text(
            CurrencyFormatter.formatCompact(value),
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(label,
            style: const TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,),),
      ],
    );
  }
}