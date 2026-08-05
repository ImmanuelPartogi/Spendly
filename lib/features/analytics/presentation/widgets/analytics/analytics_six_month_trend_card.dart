import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/utils/currency_formatter.dart';
import '../../../../../core/utils/date_formatter.dart';
import '../../../domain/providers/analytics_providers.dart';

class AnalyticsSixMonthTrendCard extends ConsumerWidget {
  final bool isDark;

  const AnalyticsSixMonthTrendCard({super.key, required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final card = isDark ? AppColors.cardDark : AppColors.card;
    final bdr = isDark ? AppColors.borderDark : AppColors.border;
    final txtPrim = isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;
    final txtSec = isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;

    final trendAsync = ref.watch(sixMonthsTrendProvider);

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: bdr, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: isDark ? 0.18 : 0.10),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.show_chart_rounded, size: 18, color: AppColors.primary),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'six_month_trend'.tr(),
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: txtPrim,
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  _LegendDot(color: AppColors.income, label: 'income'.tr(), txtSec: txtSec),
                  const SizedBox(width: 12),
                  _LegendDot(color: AppColors.expense, label: 'expense'.tr(), txtSec: txtSec),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          trendAsync.when(
            loading: () => const SizedBox(
              height: 180,
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                ),
              ),
            ),
            error: (e, _) => SizedBox(
              height: 180,
              child: Center(child: Text('${'error_occurred'.tr()}: $e', style: TextStyle(color: txtSec))),
            ),
            data: (dataList) {
              if (dataList.isEmpty) {
                return SizedBox(
                  height: 180,
                  child: Center(child: Text('no_transactions'.tr(), style: TextStyle(color: txtSec))),
                );
              }

              double maxVal = 0;
              for (final d in dataList) {
                if (d.income > maxVal) maxVal = d.income;
                if (d.expense > maxVal) maxVal = d.expense;
              }
              if (maxVal == 0) maxVal = 100000;

              return SizedBox(
                height: 180,
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: maxVal * 1.15,
                    barTouchData: BarTouchData(
                      touchTooltipData: BarTouchTooltipData(
                        getTooltipColor: (_) => isDark ? AppColors.surfaceDark : Colors.black87,
                        getTooltipItem: (group, groupIndex, rod, rodIndex) {
                          final label = rodIndex == 0 ? 'income'.tr() : 'expense'.tr();
                          return BarTooltipItem(
                            '$label\n${CurrencyFormatter.formatCompact(rod.toY)}',
                            const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                          );
                        },
                      ),
                    ),
                    titlesData: FlTitlesData(
                      show: true,
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (val, meta) {
                            final idx = val.toInt();
                            if (idx < 0 || idx >= dataList.length) return const SizedBox();
                            return Padding(
                              padding: const EdgeInsetsDirectional.only(top: 8),
                              child: Text(
                                DateFormatter.formatMonthShort(dataList[idx].date, locale: context.locale.languageCode),
                                style: TextStyle(fontSize: 10, color: txtSec, fontWeight: FontWeight.w600),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    gridData: const FlGridData(show: false),
                    borderData: FlBorderData(show: false),
                    barGroups: dataList.asMap().entries.map((entry) {
                      final i = entry.key;
                      final d = entry.value;
                      return BarChartGroupData(
                        x: i,
                        barRods: [
                          BarChartRodData(
                            toY: d.income,
                            color: AppColors.income,
                            width: 10,
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                          ),
                          BarChartRodData(
                            toY: d.expense,
                            color: AppColors.expense,
                            width: 10,
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  final Color txtSec;
  const _LegendDot({required this.color, required this.label, required this.txtSec});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 11, color: txtSec, fontWeight: FontWeight.w500)),
      ],
    );
  }
}
