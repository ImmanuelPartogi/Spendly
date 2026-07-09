import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/spendly_shimmer.dart';
import '../widgets/analytics/analytics_comparison_cta.dart';
import '../widgets/analytics/analytics_daily_card.dart';
import '../widgets/analytics/analytics_date_header.dart';
import '../widgets/analytics/analytics_insight_card.dart';
import '../widgets/analytics/analytics_summary_row.dart';
import '../widgets/analytics/analytics_weekday_card.dart';

const double _kBottomPad = 108.0;

class AnalyticsScreen extends ConsumerStatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  ConsumerState<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends ConsumerState<AnalyticsScreen> {
  /// 0 = minggu ini, 1 = minggu lalu, dst.
  /// -1 = sentinel: bulan ini
  /// -2 = sentinel: rentang kustom
  int _weekOffset = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _applyWeekRange());
  }

  void _applyWeekRange() {
    final now = DateTime.now();
    final monday = now.subtract(
      Duration(days: now.weekday - 1 + _weekOffset * 7),
    );
    final sunday = monday.add(const Duration(days: 6));
    ref.read(analyticsCustomRangeProvider.notifier).state = (
      start: DateTime(monday.year, monday.month, monday.day),
      end: DateTime(sunday.year, sunday.month, sunday.day, 23, 59, 59),
    );
    ref.read(analyticsPeriodProvider.notifier).state = AnalyticsPeriod.custom;
  }

  void _onPrevWeek() {
    setState(() => _weekOffset++);
    _applyWeekRange();
  }

  void _onNextWeek() {
    if (_weekOffset > 0) {
      setState(() => _weekOffset--);
      _applyWeekRange();
    }
  }

  Future<void> _openFilter() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    await showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _FilterSheet(
        isDark: isDark,
        onThisWeek: () {
          Navigator.pop(ctx);
          setState(() => _weekOffset = 0);
          _applyWeekRange();
        },
        onThisMonth: () {
          Navigator.pop(ctx);
          setState(() => _weekOffset = -1);
          ref.read(analyticsPeriodProvider.notifier).state =
              AnalyticsPeriod.thisMonth;
        },
        onCustom: () async {
          Navigator.pop(ctx);
          final r = await showDateRangePicker(
            context: context,
            firstDate: DateTime(2020),
            lastDate: DateTime.now(),
            builder: (rCtx, child) => Theme(
              data: Theme.of(rCtx).copyWith(
                colorScheme: ColorScheme.fromSeed(
                  seedColor: AppColors.primary,
                  brightness: Theme.of(rCtx).brightness,
                ),
              ),
              child: child!,
            ),
          );
          if (r != null && mounted) {
            ref.read(analyticsCustomRangeProvider.notifier).state =
                (start: r.start, end: r.end);
            ref.read(analyticsPeriodProvider.notifier).state =
                AnalyticsPeriod.custom;
            setState(() => _weekOffset = -2);
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.backgroundDark : AppColors.background;
    final safeTop = MediaQuery.of(context).padding.top;
    final safeBottom = MediaQuery.of(context).padding.bottom;
    final txtSec =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;

    final txAsync = ref.watch(analyticsTransactionsProvider);
    final expense = ref.watch(analyticsExpenseProvider);
    final income = ref.watch(analyticsIncomeProvider);
    final categories = ref.watch(analyticsCategoryBreakdownProvider);
    final weekdayData = ref.watch(analyticsWeekdaySpendingProvider);
    final daily = ref.watch(analyticsDailySpendingProvider);

    return Scaffold(
      backgroundColor: bgColor,
      extendBodyBehindAppBar: true,
      body: txAsync.when(
        loading: () => const SafeArea(child: AnalyticsSkeleton()),
        error: (e, _) =>
            Center(child: Text('Terjadi kesalahan: $e', style: TextStyle(color: txtSec))),
        data: (_) => CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            _AnalyticsAppBar(
              isDark: isDark,
              safeTop: safeTop,
              isFiltered: _weekOffset != 0,
              onFilter: _openFilter,
            ),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                  16, 4, 16, _kBottomPad + safeBottom,),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  AnalyticsDateHeader(
                    weekOffset: _weekOffset,
                    isDark: isDark,
                    onPrevious: _onPrevWeek,
                    onNext: _onNextWeek,
                    canGoNext: _weekOffset > 0,
                  ),
                  const SizedBox(height: 16),
                  AnalyticsSummaryRow(
                      expense: expense, income: income, isDark: isDark,),
                  const SizedBox(height: 16),
                  AnalyticsDailyCard(daily: daily, isDark: isDark),
                  const SizedBox(height: 16),
                  AnalyticsWeekdayCard(weekday: weekdayData, isDark: isDark),
                  const SizedBox(height: 16),
                  AnalyticsInsightCard(
                    categories: categories,
                    weekday: weekdayData,
                    expense: expense,
                    daily: daily,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 16),
                  AnalyticsComparisonCta(isDark: isDark),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── App Bar ──────────────────────────────────────────────────────────────────

class _AnalyticsAppBar extends StatelessWidget {
  final bool isDark;
  final double safeTop;
  final bool isFiltered;
  final VoidCallback onFilter;

  const _AnalyticsAppBar({
    required this.isDark,
    required this.safeTop,
    required this.isFiltered,
    required this.onFilter,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = isDark ? AppColors.backgroundDark : AppColors.background;
    final txtPrim = isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;
    final txtSec =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;

    return SliverAppBar(
      expandedHeight: 88,
      collapsedHeight: 56,
      pinned: true,
      backgroundColor: bgColor,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      automaticallyImplyLeading: false,
      flexibleSpace: LayoutBuilder(builder: (context, constraints) {
        final isCollapsed = constraints.maxHeight < 72 + safeTop;
        return Stack(clipBehavior: Clip.none, children: [
          // Expanded title
          AnimatedOpacity(
            opacity: isCollapsed ? 0.0 : 1.0,
            duration: const Duration(milliseconds: 150),
            child: Align(
              alignment: Alignment.bottomLeft,
              child: Padding(
                padding: EdgeInsets.fromLTRB(20, safeTop + 12, 60, 14),
                child: OverflowBox(
                  alignment: Alignment.bottomLeft,
                  maxHeight: double.infinity,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Laporan &',
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: txtSec,),),
                      Text('Analytics',
                          style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              color: txtPrim,
                              letterSpacing: -0.8,
                              height: 1.1,),),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Collapsed title
          AnimatedOpacity(
            opacity: isCollapsed ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 150),
            child: Align(
              alignment: Alignment.bottomLeft,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 60, 14),
                child: Text('Analytics',
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: txtPrim,
                        letterSpacing: -0.6,),),
              ),
            ),
          ),
          // Filter button (now functional)
          Positioned(
            right: 16,
            bottom: 10,
            child: GestureDetector(
              onTap: onFilter,
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: isFiltered
                      ? AppColors.primary.withValues(alpha: 0.12)
                      : (isDark ? AppColors.surfaceDark : AppColors.surface),
                  borderRadius: BorderRadius.circular(11),
                  border: Border.all(
                    color: isFiltered
                        ? AppColors.primary.withValues(alpha: 0.40)
                        : (isDark ? AppColors.borderDark : AppColors.border),
                    width: 0.5,
                  ),
                ),
                child: Icon(Icons.tune_rounded,
                    size: 17,
                    color: isFiltered
                        ? AppColors.primary
                        : (isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondary),),
              ),
            ),
          ),
        ],);
      },),
    );
  }
}

// ─── Filter Sheet ─────────────────────────────────────────────────────────────

class _FilterSheet extends StatelessWidget {
  final bool isDark;
  final VoidCallback onThisWeek;
  final VoidCallback onThisMonth;
  final VoidCallback onCustom;

  const _FilterSheet({
    required this.isDark,
    required this.onThisWeek,
    required this.onThisMonth,
    required this.onCustom,
  });

  @override
  Widget build(BuildContext context) {
    final txtPrim = isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;
    final txtSec =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.borderDark : AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text('Filter Periode',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: txtPrim,
                    letterSpacing: -0.4,),),
            const SizedBox(height: 4),
            Text('Pilih rentang waktu yang ingin ditampilkan',
                style: TextStyle(fontSize: 12, color: txtSec),),
            const SizedBox(height: 16),
            _SheetOption(
              label: 'Minggu Ini',
              subtitle: 'Tampilkan data 7 hari berjalan',
              icon: Icons.calendar_view_week_rounded,
              onTap: onThisWeek,
              isDark: isDark,
            ),
            const SizedBox(height: 8),
            _SheetOption(
              label: 'Bulan Ini',
              subtitle: 'Tampilkan seluruh data bulan ini',
              icon: Icons.calendar_month_rounded,
              onTap: onThisMonth,
              isDark: isDark,
            ),
            const SizedBox(height: 8),
            _SheetOption(
              label: 'Rentang Kustom',
              subtitle: 'Pilih tanggal mulai dan akhir sendiri',
              icon: Icons.date_range_rounded,
              onTap: onCustom,
              isDark: isDark,
            ),
          ],
        ),
      ),
    );
  }
}

class _SheetOption extends StatelessWidget {
  final String label;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;
  final bool isDark;

  const _SheetOption({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final surf = isDark ? AppColors.surfaceDark : AppColors.surface;
    final bdr = isDark ? AppColors.borderDark : AppColors.border;
    final txtPrim = isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;
    final txtSec =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: surf,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: bdr, width: 0.5),
        ),
        child: Row(children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.primary, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: txtPrim,),),
                Text(subtitle,
                    style: TextStyle(fontSize: 11, color: txtSec),),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: txtSec, size: 18),
        ],),
      ),
    );
  }
}