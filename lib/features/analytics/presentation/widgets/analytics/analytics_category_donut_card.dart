import 'package:easy_localization/easy_localization.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/utils/category_utils.dart';
import '../../../../../core/utils/currency_formatter.dart';

class AnalyticsCategoryDonutCard extends ConsumerWidget {
  final Map<String, double> categories;
  final double totalExpense;
  final bool isDark;

  const AnalyticsCategoryDonutCard({
    super.key,
    required this.categories,
    required this.totalExpense,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final card = isDark ? AppColors.cardDark : AppColors.card;
    final bdr = isDark ? AppColors.borderDark : AppColors.border;
    final txtPrim = isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;
    final txtSec = isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;

    final entries = categories.entries.where((e) => e.value > 0).toList();

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
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: isDark ? 0.18 : 0.10),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.pie_chart_rounded, size: 18, color: AppColors.primary),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'category_breakdown'.tr(),
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: txtPrim,
                      letterSpacing: -0.3,
                    ),
                  ),
                  Text(
                    '${entries.length} ${'categories'.tr()}',
                    style: TextStyle(fontSize: 12, color: txtSec),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (entries.isEmpty || totalExpense <= 0)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  'no_transactions'.tr(),
                  style: TextStyle(fontSize: 13, color: txtSec),
                ),
              ),
            )
          else ...[
            SizedBox(
              height: 180,
              child: Stack(
                children: [
                  PieChart(
                    PieChartData(
                      centerSpaceRadius: 45,
                      sectionsSpace: 2,
                      startDegreeOffset: 270,
                      sections: entries.map((e) {
                        final cat = e.key;
                        final val = e.value;
                        final pct = (val / totalExpense) * 100;
                        final color = CategoryUtils.getColor(cat);
                        return PieChartSectionData(
                          color: color,
                          value: val,
                          title: pct >= 8 ? '${pct.toStringAsFixed(0)}%' : '',
                          radius: 36,
                          titleStyle: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'expense'.tr(),
                          style: TextStyle(fontSize: 10.5, color: txtSec, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          CurrencyFormatter.formatCompact(totalExpense),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: txtPrim,
                            letterSpacing: -0.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Divider(height: 1, color: isDark ? AppColors.dividerDark : AppColors.divider),
            const SizedBox(height: 14),
            // Legend
            Column(
              children: entries.map((e) {
                final cat = e.key;
                final amt = e.value;
                final pct = (amt / totalExpense) * 100;
                final catColor = CategoryUtils.getColor(cat);
                return Padding(
                  padding: const EdgeInsetsDirectional.only(bottom: 10),
                  child: Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: catColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Icon(CategoryUtils.getIcon(cat), size: 14, color: catColor),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          CategoryUtils.getLocalizedName(cat),
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: txtPrim,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        '${pct.toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: txtSec,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        CurrencyFormatter.formatCompact(amt),
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: txtPrim,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}
