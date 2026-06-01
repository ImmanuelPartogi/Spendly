import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../features/transactions/domain/entities/transaction_entity.dart';
import '../../../../shared/widgets/spendly_shimmer.dart';
import '../widgets/comparison/comparison_category_card.dart';
import '../widgets/comparison/comparison_chart_card.dart';
import '../widgets/comparison/comparison_donut_card.dart';
import '../widgets/comparison/comparison_insight_panel.dart';
import '../widgets/comparison/comparison_period_selector.dart';
import '../widgets/comparison/comparison_savings_card.dart';
import '../widgets/comparison/comparison_summary_row.dart';

// ─── Model ────────────────────────────────────────────────────────────────────

enum ComparisonPeriod {
  weekly('Mingguan'),
  monthly('Bulanan'),
  quarterly('3 Bulan'),
  yearly('Tahunan');

  final String label;
  const ComparisonPeriod(this.label);
}

class ComparisonData {
  final String key;
  final String label;
  final double income;
  final double expense;

  const ComparisonData({
    required this.key,
    required this.label,
    required this.income,
    required this.expense,
  });

  double get savings => income - expense;
  double get savingsRate =>
      income > 0 ? ((income - expense) / income * 100) : 0;
}

// ─── Screen ───────────────────────────────────────────────────────────────────

class IncomeExpenseComparisonScreen extends ConsumerStatefulWidget {
  const IncomeExpenseComparisonScreen({super.key});

  @override
  ConsumerState<IncomeExpenseComparisonScreen> createState() =>
      _IncomeExpenseComparisonScreenState();
}

class _IncomeExpenseComparisonScreenState
    extends ConsumerState<IncomeExpenseComparisonScreen>
    with SingleTickerProviderStateMixin {
  ComparisonPeriod _period = ComparisonPeriod.monthly;
  final Set<String> _selIncome = {};
  final Set<String> _selExpense = {};
  late final TabController _tabCtrl;
  int _touchedBar = -1;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  // ── Data helpers ──────────────────────────────────────────────────────────

  List<ComparisonData> _buildData(List<TransactionEntity> all) {
    final filtered = all.where((tx) {
      if (tx.isExpense) {
        return _selExpense.isEmpty || _selExpense.contains(tx.category);
      } else {
        return _selIncome.isEmpty || _selIncome.contains(tx.category);
      }
    }).toList();

    final Map<String, Map<String, double>> grouped = {};
    for (final tx in filtered) {
      final key = _periodKey(tx.date);
      grouped.putIfAbsent(key, () => {'income': 0, 'expense': 0});
      if (tx.isExpense) {
        grouped[key]!['expense'] = (grouped[key]!['expense'] ?? 0) + tx.amount;
      } else {
        grouped[key]!['income'] = (grouped[key]!['income'] ?? 0) + tx.amount;
      }
    }

    final entries = grouped.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    final maxP = _period == ComparisonPeriod.yearly ? 5 : 6;
    final sliced = entries.length > maxP
        ? entries.sublist(entries.length - maxP)
        : entries;

    return sliced
        .map((e) => ComparisonData(
              key: e.key,
              label: _periodLabel(e.key),
              income: e.value['income'] ?? 0,
              expense: e.value['expense'] ?? 0,
            ))
        .toList();
  }

  String _periodKey(DateTime date) {
    switch (_period) {
      case ComparisonPeriod.weekly:
        final dayOfYear = date.difference(DateTime(date.year)).inDays + 1;
        final week = ((dayOfYear - date.weekday + 10) ~/ 7);
        return '${date.year}-W${week.toString().padLeft(2, '0')}';
      case ComparisonPeriod.monthly:
        return '${date.year}-${date.month.toString().padLeft(2, '0')}';
      case ComparisonPeriod.quarterly:
        return '${date.year}-Q${((date.month - 1) ~/ 3) + 1}';
      case ComparisonPeriod.yearly:
        return '${date.year}';
    }
  }

  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
    'Jul', 'Agt', 'Sep', 'Okt', 'Nov', 'Des',
  ];

  String _periodLabel(String key) {
    if (key.contains('-W')) return 'W${key.split('-W')[1]}';
    if (key.contains('-Q')) {
      final p = key.split('-Q');
      return 'Q${p[1]} ${p[0].substring(2)}';
    }
    if (key.contains('-')) {
      final p = key.split('-');
      final m = int.tryParse(p[1]) ?? 1;
      return '${_months[m - 1]} ${p[0].substring(2)}';
    }
    return key;
  }

  Map<String, double> _categoryTotals(
      List<TransactionEntity> all, bool isExpense) {
    final cats = isExpense
        ? (_selExpense.isEmpty ? null : _selExpense)
        : (_selIncome.isEmpty ? null : _selIncome);
    final result = <String, double>{};
    for (final tx in all) {
      if (tx.isExpense != isExpense) continue;
      if (cats != null && !cats.contains(tx.category)) continue;
      result[tx.category] = (result[tx.category] ?? 0) + tx.amount;
    }
    final sorted = result.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return Map.fromEntries(sorted);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.backgroundDark : AppColors.background;
    final txtSec =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;
    final safeTop = MediaQuery.of(context).padding.top;
    final txAsync = ref.watch(allTransactionsStreamProvider);

    return Scaffold(
      backgroundColor: bgColor,
      body: txAsync.when(
        loading: () => const SafeArea(child: AnalyticsSkeleton()),
        error: (e, _) =>
            Center(child: Text('Terjadi kesalahan: $e', style: TextStyle(color: txtSec))),
        data: (all) {
          final data = _buildData(all);
          final incomeCats = _categoryTotals(all, false);
          final expenseCats = _categoryTotals(all, true);
          final allIncomeCats = _categoryTotals(all, false);
          final allExpenseCats = _categoryTotals(all, true);
          final totalIncome = data.fold(0.0, (s, d) => s + d.income);
          final totalExpense = data.fold(0.0, (s, d) => s + d.expense);
          final totalSavings = totalIncome - totalExpense;
          final maxVal = data.fold(
            0.0,
            (m, d) => [m, d.income, d.expense].reduce((a, b) => a > b ? a : b),
          );

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // ── App Bar ────────────────────────────────────────────────
              _ComparisonAppBar(
                isDark: isDark,
                safeTop: safeTop,
                onBack: () => Navigator.pop(context),
              ),

              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    ComparisonPeriodSelector(
                      selected: _period,
                      isDark: isDark,
                      onChanged: (p) => setState(() {
                        _period = p;
                        _touchedBar = -1;
                      }),
                    ),
                    const SizedBox(height: 16),
                    ComparisonSummaryRow(
                      income: totalIncome,
                      expense: totalExpense,
                      savings: totalSavings,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 16),
                    ComparisonInsightPanel(
                      data: data,
                      totalIncome: totalIncome,
                      totalExpense: totalExpense,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 16),
                    ComparisonChartCard(
                      data: data,
                      maxVal: maxVal,
                      isDark: isDark,
                      touchedIndex: _touchedBar,
                      onTouch: (i) => setState(() => _touchedBar = i),
                    ),
                    const SizedBox(height: 16),
                    ComparisonDonutCard(
                      incomeCats: allIncomeCats,
                      expenseCats: allExpenseCats,
                      totalIncome: totalIncome,
                      totalExpense: totalExpense,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 16),
                    if (data.isNotEmpty) ...[
                      ComparisonSavingsCard(data: data, isDark: isDark),
                      const SizedBox(height: 16),
                    ],
                    ComparisonCategoryCard(
                      tabCtrl: _tabCtrl,
                      incomeCats: incomeCats,
                      expenseCats: expenseCats,
                      selectedIncome: _selIncome,
                      selectedExpense: _selExpense,
                      totalIncome: totalIncome,
                      totalExpense: totalExpense,
                      isDark: isDark,
                      onToggleIncome: (cat) => setState(() {
                        _selIncome.contains(cat)
                            ? _selIncome.remove(cat)
                            : _selIncome.add(cat);
                      }),
                      onToggleExpense: (cat) => setState(() {
                        _selExpense.contains(cat)
                            ? _selExpense.remove(cat)
                            : _selExpense.add(cat);
                      }),
                      onClearIncome: () => setState(() => _selIncome.clear()),
                      onClearExpense: () => setState(() => _selExpense.clear()),
                    ),
                  ]),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ─── App Bar ──────────────────────────────────────────────────────────────────

class _ComparisonAppBar extends StatelessWidget {
  final bool isDark;
  final double safeTop;
  final VoidCallback onBack;

  const _ComparisonAppBar({
    required this.isDark,
    required this.safeTop,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor   = isDark ? AppColors.backgroundDark : AppColors.background;
    final txtPrim   = isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;
    final txtSec    = isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;
    final surfColor = isDark ? AppColors.surfaceDark : AppColors.surface;
    final bdrColor  = isDark ? AppColors.borderDark : AppColors.border;

    // Back button widget — dipakai ulang di kedua state
    Widget backButton = GestureDetector(
      onTap: onBack,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: surfColor,
          borderRadius: BorderRadius.circular(11),
          border: Border.all(color: bdrColor, width: 0.5),
        ),
        child: Icon(
          Icons.arrow_back_ios_new_rounded,
          size: 15,
          color: txtPrim,
        ),
      ),
    );

    return SliverAppBar(
      expandedHeight: 88,
      collapsedHeight: 56,
      pinned: true,
      backgroundColor: bgColor,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      automaticallyImplyLeading: false,
      // Tidak pakai leading — back button masuk ke flexibleSpace
      flexibleSpace: LayoutBuilder(builder: (context, constraints) {
        final isCollapsed = constraints.maxHeight < 72 + safeTop;

        return Stack(clipBehavior: Clip.none, children: [
          // ── Expanded: back button + "Laporan &\nPerbandingan" sejajar ──
          AnimatedOpacity(
            opacity: isCollapsed ? 0.0 : 1.0,
            duration: const Duration(milliseconds: 150),
            child: Align(
              alignment: Alignment.bottomLeft,
              child: Padding(
                padding: EdgeInsets.fromLTRB(16, safeTop, 20, 14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Back button sejajar dengan baseline teks terbesar
                    Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: backButton,
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Laporan &',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: txtSec,
                          ),
                        ),
                        Text(
                          'Perbandingan',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: txtPrim,
                            letterSpacing: -0.8,
                            height: 1.1,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Collapsed: back button + "Perbandingan" sejajar ────────────
          AnimatedOpacity(
            opacity: isCollapsed ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 150),
            child: Align(
              alignment: Alignment.bottomLeft,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 20, 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    backButton,
                    const SizedBox(width: 12),
                    Text(
                      'Perbandingan',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: txtPrim,
                        letterSpacing: -0.6,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ]);
      }),
    );
  }
}