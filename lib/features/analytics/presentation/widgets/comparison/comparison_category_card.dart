import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/category_utils.dart';
import '../../../../../core/utils/currency_formatter.dart';

class ComparisonCategoryCard extends StatelessWidget {
  final TabController tabCtrl;
  final Map<String, double> incomeCats;
  final Map<String, double> expenseCats;
  final Set<String> selectedIncome;
  final Set<String> selectedExpense;
  final double totalIncome;
  final double totalExpense;
  final bool isDark;
  final ValueChanged<String> onToggleIncome;
  final ValueChanged<String> onToggleExpense;
  final VoidCallback onClearIncome;
  final VoidCallback onClearExpense;

  const ComparisonCategoryCard({
    super.key,
    required this.tabCtrl,
    required this.incomeCats,
    required this.expenseCats,
    required this.selectedIncome,
    required this.selectedExpense,
    required this.totalIncome,
    required this.totalExpense,
    required this.isDark,
    required this.onToggleIncome,
    required this.onToggleExpense,
    required this.onClearIncome,
    required this.onClearExpense,
  });

  @override
  Widget build(BuildContext context) {
    final card = isDark ? AppColors.cardDark : AppColors.card;
    final bdr = isDark ? AppColors.borderDark : AppColors.border;
    final surf = isDark ? AppColors.surfaceDark : AppColors.surface;
    final txtPrim = isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;
    final txtSec =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: bdr, width: 0.5),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 20, 18, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Rincian Kategori',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: txtPrim,
                      letterSpacing: -0.3,),),
              const SizedBox(height: 3),
              Text('Tap kategori untuk filter grafik utama',
                  style: TextStyle(fontSize: 11, color: txtSec),),
              const SizedBox(height: 14),
              Container(
                height: 40,
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                    color: surf, borderRadius: BorderRadius.circular(12),),
                child: TabBar(
                  controller: tabCtrl,
                  indicator: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(9),
                    boxShadow: [
                      BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.25),
                          blurRadius: 8,
                          offset: const Offset(0, 2),),
                    ],
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  labelColor: Colors.white,
                  unselectedLabelColor: txtSec,
                  labelStyle: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 12,),
                  unselectedLabelStyle: const TextStyle(
                      fontWeight: FontWeight.w500, fontSize: 12,),
                  dividerColor: Colors.transparent,
                  overlayColor:
                      WidgetStateProperty.all(Colors.transparent),
                  tabs: const [
                    Tab(text: 'Pemasukan'),
                    Tab(text: 'Pengeluaran'),
                  ],
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 340,
          child: TabBarView(
            controller: tabCtrl,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _CatList(
                cats: incomeCats, selected: selectedIncome,
                isExpense: false, isDark: isDark, total: totalIncome,
                onToggle: onToggleIncome, onClear: onClearIncome,
              ),
              _CatList(
                cats: expenseCats, selected: selectedExpense,
                isExpense: true, isDark: isDark, total: totalExpense,
                onToggle: onToggleExpense, onClear: onClearExpense,
              ),
            ],
          ),
        ),
      ],),
    );
  }
}

class _CatList extends StatelessWidget {
  final Map<String, double> cats;
  final Set<String> selected;
  final bool isExpense;
  final bool isDark;
  final double total;
  final ValueChanged<String> onToggle;
  final VoidCallback onClear;

  const _CatList({
    required this.cats, required this.selected, required this.isExpense,
    required this.isDark, required this.total, required this.onToggle,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final accent = isExpense ? AppColors.expense : AppColors.income;
    final txtPrim = isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;
    final txtSec =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;
    final surf = isDark ? AppColors.surfaceDark : AppColors.surface;
    final bdr = isDark ? AppColors.borderDark : AppColors.border;

    if (cats.isEmpty) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
                color: surf, borderRadius: BorderRadius.circular(12),),
            child: Icon(
                isExpense
                    ? Icons.shopping_cart_outlined
                    : Icons.account_balance_wallet_outlined,
                color: isDark ? AppColors.textHintDark : AppColors.textHint,
                size: 20,),
          ),
          const SizedBox(height: 10),
          Text(
              'Tidak ada data ${isExpense ? "pengeluaran" : "pemasukan"}',
              style: TextStyle(color: txtSec, fontSize: 12),),
        ],),
      );
    }

    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 8),
        child: Row(children: [
          Container(
            width: 5, height: 5,
            decoration: BoxDecoration(
              color: selected.isEmpty ? accent : AppColors.warning,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
              selected.isEmpty
                  ? 'Semua kategori'
                  : '${selected.length} kategori aktif',
              style: TextStyle(
                  fontSize: 11, color: txtSec, fontWeight: FontWeight.w500,),),
          const Spacer(),
          if (selected.isNotEmpty)
            GestureDetector(
              onTap: onClear,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text('Atur Ulang',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: accent,),),
              ),
            ),
        ],),
      ),
      Expanded(
        child: ListView.builder(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
          itemCount: cats.length,
          itemBuilder: (_, i) {
            final entry = cats.entries.elementAt(i);
            final cat = entry.key;
            final val = entry.value;
            final pct = total > 0 ? val / total : 0.0;
            final catColor = CategoryUtils.getColor(cat);
            final catIcon = CategoryUtils.getIcon(cat);
            final isActive = selected.isEmpty || selected.contains(cat);
            final isPinned = selected.contains(cat);

            return GestureDetector(
              onTap: () => onToggle(cat),
              child: AnimatedOpacity(
                duration: kDurationFast,
                opacity: isActive ? 1.0 : 0.38,
                child: AnimatedContainer(
                  duration: kDurationFast,
                  curve: kCurveDefault,
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.fromLTRB(12, 11, 12, 11),
                  decoration: BoxDecoration(
                    color: isPinned ? catColor.withValues(alpha: 0.07) : surf,
                    borderRadius: BorderRadius.circular(13),
                    border: Border.all(
                      color: isPinned
                          ? catColor.withValues(alpha: 0.35)
                          : bdr,
                      width: isPinned ? 1.0 : 0.5,
                    ),
                  ),
                  child: Row(children: [
                    Container(
                      width: 34, height: 34,
                      decoration: BoxDecoration(
                        color: catColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: Icon(catIcon, color: catColor, size: 16),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(cat,
                              style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: txtPrim,
                                  letterSpacing: -0.1,),),
                          const SizedBox(height: 5),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(3),
                            child: Stack(children: [
                              Container(
                                  height: 3,
                                  color: catColor.withValues(alpha: 0.10),),
                              FractionallySizedBox(
                                widthFactor: pct.clamp(0.01, 1.0),
                                child: Container(
                                    height: 3, color: catColor,),
                              ),
                            ],),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(CurrencyFormatter.formatCompact(val),
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: catColor,
                                letterSpacing: -0.3,),),
                        const SizedBox(height: 2),
                        Text('${(pct * 100).toStringAsFixed(0)}%',
                            style: TextStyle(
                                fontSize: 10,
                                color: txtSec,
                                fontWeight: FontWeight.w500,),),
                      ],
                    ),
                  ],),
                ),
              ),
            );
          },
        ),
      ),
    ],);
  }
}