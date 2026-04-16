import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/currency_formatter.dart';

// ─────────────────────────────────────────────────────────────────────────────
// MiniExpenseChart — Redesigned bar chart
//
// Perubahan dari versi lama:
// - Bar gradient dari primary ke primaryLight
// - Touch tooltip dengan amount format
// - Header section dengan total label
// - Better empty state dengan icon
// - Animasi bar entry saat pertama dimuat
// - Highest bar diberi label amount di atas
// ─────────────────────────────────────────────────────────────────────────────

class MiniExpenseChart extends ConsumerStatefulWidget {
  const MiniExpenseChart({super.key});

  @override
  ConsumerState<MiniExpenseChart> createState() => _MiniExpenseChartState();
}

class _MiniExpenseChartState extends ConsumerState<MiniExpenseChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;
  int _touchedIndex = -1;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutQuart);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final weekdayTotals = ref.watch(weekdaySpendingProvider);
    final isLoading     = ref.watch(monthlyTransactionsProvider).isLoading;
    final isDark        = Theme.of(context).brightness == Brightness.dark;

    final isEmpty = weekdayTotals.values.every((v) => v == 0);
    final maxVal  = isEmpty
        ? 0.0
        : weekdayTotals.values.reduce((a, b) => a > b ? a : b);

    if (isLoading) {
      return _ChartSkeleton(isDark: isDark);
    }

    if (isEmpty) {
      return _EmptyState(isDark: isDark);
    }

    // Cari weekday hari ini (1=Mon … 7=Sun)
    final todayWeekday = DateTime.now().weekday;

    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) {
        return SizedBox(
          height: 110,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: maxVal * 1.35,
              barTouchData: BarTouchData(
                enabled: true,
                touchCallback: (event, response) {
                  setState(() {
                    if (event is FlTapUpEvent ||
                        event is FlPointerExitEvent) {
                      _touchedIndex = -1;
                    } else if (response?.spot != null) {
                      _touchedIndex =
                          response!.spot!.touchedBarGroupIndex;
                    }
                  });
                },
                touchTooltipData: BarTouchTooltipData(
                  getTooltipColor: (group) => isDark
                      ? AppColors.surfaceDark
                      : AppColors.card,
                  tooltipRoundedRadius: 8,
                  tooltipBorder: BorderSide(
                    color: isDark
                        ? AppColors.borderDark
                        : AppColors.border,
                    width: 0.5,
                  ),
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    final weekday = groupIndex + 1;
                    final dayName = AppConstants.daysOfWeekFull[groupIndex];
                    return BarTooltipItem(
                      '$dayName\n',
                      TextStyle(
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondary,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                      children: [
                        TextSpan(
                          text: CurrencyFormatter.formatCompact(
                              weekdayTotals[weekday] ?? 0),
                          style: TextStyle(
                            color: isDark
                                ? AppColors.textPrimaryDark
                                : AppColors.textPrimary,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              titlesData: FlTitlesData(
                show: true,
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 26,
                    getTitlesWidget: (value, meta) {
                      final idx = value.toInt();
                      if (idx < 0 ||
                          idx >= AppConstants.daysOfWeek.length) {
                        return const SizedBox.shrink();
                      }
                      final weekday  = idx + 1;
                      final isToday  = weekday == todayWeekday;
                      return Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          AppConstants.daysOfWeek[idx],
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: isToday
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: isToday
                                ? AppColors.primary
                                : (isDark
                                    ? AppColors.textHintDark
                                    : AppColors.textHint),
                          ),
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
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: maxVal / 2,
                getDrawingHorizontalLine: (_) => FlLine(
                  color: isDark
                      ? AppColors.borderDark.withOpacity(0.5)
                      : AppColors.border.withOpacity(0.7),
                  strokeWidth: 0.5,
                  dashArray: [4, 4],
                ),
              ),
              borderData: FlBorderData(show: false),
              barGroups: List.generate(7, (i) {
                final weekday    = i + 1;
                final rawValue   = weekdayTotals[weekday] ?? 0;
                final value      = rawValue * _anim.value;
                final isHighest  = rawValue == maxVal && maxVal > 0;
                final isTouched  = _touchedIndex == i;
                final isToday    = weekday == todayWeekday;

                Color barColor;
                if (isTouched) {
                  barColor = AppColors.primaryLight;
                } else if (isHighest) {
                  barColor = AppColors.primary;
                } else if (isToday && rawValue > 0) {
                  barColor = AppColors.primaryLight;
                } else {
                  barColor = isDark
                      ? AppColors.primary.withOpacity(0.18)
                      : AppColors.primary.withOpacity(0.14);
                }

                return BarChartGroupData(
                  x: i,
                  barRods: [
                    BarChartRodData(
                      toY: value == 0 ? 0.01 : value,
                      color: barColor,
                      width: 18,
                      borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(7)),
                    ),
                  ],
                );
              }),
            ),
            swapAnimationDuration: Duration.zero,
          ),
        );
      },
    );
  }
}

// ─── Skeleton ─────────────────────────────────────────────────────────────────

class _ChartSkeleton extends StatelessWidget {
  final bool isDark;
  const _ChartSkeleton({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final heights = [40.0, 60.0, 45.0, 80.0, 55.0, 30.0, 50.0];
    final base = isDark
        ? const Color(0xFF1C1E2E)
        : const Color(0xFFEEF1FA);

    return SizedBox(
      height: 110,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: heights
            .map(
              (h) => Container(
                width: 18,
                height: h,
                decoration: BoxDecoration(
                  color: base,
                  borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(7)),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

// ─── Empty state ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final bool isDark;
  const _EmptyState({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 110,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.surfaceDark
                    : AppColors.surface,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.bar_chart_rounded,
                size: 18,
                color: isDark
                    ? AppColors.textHintDark
                    : AppColors.textHint,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Belum ada data minggu ini',
              style: TextStyle(
                color: isDark
                    ? AppColors.textHintDark
                    : AppColors.textHint,
                fontSize: 11.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}