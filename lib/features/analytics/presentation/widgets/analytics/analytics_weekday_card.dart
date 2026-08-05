import 'package:easy_localization/easy_localization.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/utils/currency_formatter.dart';
import '../../../../../core/utils/date_formatter.dart';

class AnalyticsWeekdayCard extends StatelessWidget {
  final Map<int, double> weekday;
  final bool isDark;

  const AnalyticsWeekdayCard({
    super.key,
    required this.weekday,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final card = isDark ? AppColors.cardDark : AppColors.card;
    final bdr = isDark ? AppColors.borderDark : AppColors.border;
    final txtPrim = isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;
    final txtSec =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;

    final maxDay = weekday.entries.isEmpty
        ? 0
        : weekday.entries.reduce((a, b) => a.value > b.value ? a : b).key;

    final maxDayName = maxDay > 0
        ? DateFormatter.formatWeekdayName(maxDay, locale: context.locale.languageCode)
        : '';

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: bdr, width: 0.5),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('daily_pattern'.tr(),
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: txtPrim,
                      letterSpacing: -0.3,),),
              const SizedBox(height: 3),
              Text('highest_spending_day'.tr(),
                  style: TextStyle(fontSize: 11, color: txtSec),),
            ],),
            if (weekday.values.any((v) => v > 0))
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.local_fire_department_rounded,
                      size: 11, color: AppColors.primary,),
                  const SizedBox(width: 4),
                  Text(maxDayName,
                      style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,),),
                ],),
              ),
          ],
        ),
        const SizedBox(height: 20),
        _WeekdayBarChart(data: weekday, isDark: isDark),
      ],),
    );
  }
}

class _WeekdayBarChart extends StatelessWidget {
  final Map<int, double> data;
  final bool isDark;

  const _WeekdayBarChart({required this.data, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final sec = isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;
    final div = isDark
        ? AppColors.borderDark.withValues(alpha: 0.5)
        : AppColors.border.withValues(alpha: 0.7);
    final maxVal = data.values.fold(0.0, (a, b) => a > b ? a : b);
    final today = DateTime.now().weekday;

    if (maxVal == 0) {
      return SizedBox(
        height: 100,
        child: Center(
          child: Text('no_data_yet'.tr(),
              style: TextStyle(fontSize: 12, color: AppColors.textHint),),
        ),
      );
    }

    return SizedBox(
      height: 120,
      child: BarChart(BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxVal * 1.3,
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) =>
                isDark ? AppColors.surfaceDark : AppColors.card,
            tooltipRoundedRadius: 8,
            tooltipBorder: BorderSide(
                color: isDark ? AppColors.borderDark : AppColors.border,
                width: 0.5,),
            getTooltipItem: (group, _, rod, __) {
              final dName = DateFormatter.formatWeekdayName(
                group.x + 1,
                locale: context.locale.languageCode,
              );
              return BarTooltipItem(
                '$dName\n${CurrencyFormatter.formatCompact(rod.toY)}',
                const TextStyle(
                  color: AppColors.primary,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 24,
              getTitlesWidget: (v, _) {
                final i = v.toInt();
                final isToday = (i + 1) == today;
                if (i < 0 || i >= 7) return const SizedBox.shrink();
                final dName = DateFormatter.formatWeekdayName(i + 1, locale: context.locale.languageCode);
                final shortName = dName.length > 3 ? dName.substring(0, 3) : dName;
                return Padding(
                  padding: const EdgeInsetsDirectional.only(top: 6),
                  child: Text(shortName,
                      style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
                          color: isToday ? AppColors.primary : sec,),),
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
          horizontalInterval: maxVal / 2,
          getDrawingHorizontalLine: (_) =>
              FlLine(color: div, strokeWidth: 0.5, dashArray: [4, 4]),
        ),
        borderData: FlBorderData(show: false),
        barGroups: List.generate(7, (i) {
          final wd = i + 1;
          final val = data[wd] ?? 0;
          final isMax = val == maxVal && maxVal > 0;
          final isToday = wd == today;

          final color = isMax
              ? AppColors.primary
              : isToday && val > 0
                  ? AppColors.primaryLight
                  : (isDark
                      ? AppColors.primary.withValues(alpha: 0.16)
                      : AppColors.primary.withValues(alpha: 0.12));

          return BarChartGroupData(x: i, barRods: [
            BarChartRodData(
              toY: val == 0 ? 0.01 : val,
              color: color,
              width: 22,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(7)),
            ),
          ],);
        }),
      ),),
    );
  }
}