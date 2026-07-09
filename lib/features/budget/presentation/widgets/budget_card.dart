import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/category_utils.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../shared/widgets/spendly_card.dart';
import '../../domain/entities/budget_entity.dart';

class BudgetCard extends StatelessWidget {
  final BudgetEntity budget;
  final bool isDark;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const BudgetCard({
    super.key,
    required this.budget,
    required this.isDark,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final color = CategoryUtils.getColor(budget.category);
    final icon = CategoryUtils.getIcon(budget.category);
    final pct = budget.percentage;
    final txtPrim = isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;
    final txtSec =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;
    final txtHint = isDark ? AppColors.textHintDark : AppColors.textHint;
    final surfColor =
        isDark ? AppColors.surfaceDark : const Color(0xFFF4F6FB);

    final progressColor = budget.isExceeded
        ? AppColors.error
        : budget.isWarning
            ? AppColors.warning
            : AppColors.income;

    final pctLabel = budget.isExceeded
        ? 'Terlampaui'
        : budget.isWarning
            ? 'Hampir di batas'
            : '${(pct * 100).round()}% terpakai';

    return SpendlyCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // ── Header row ──────────────────────────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: isDark ? 0.16 : 0.10),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: 21),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(budget.category,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: txtPrim,
                          letterSpacing: -0.2,
                        ),),
                    const SizedBox(height: 3),
                    Row(children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                            color: progressColor, shape: BoxShape.circle,),
                      ),
                      const SizedBox(width: 5),
                      Text(pctLabel,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: budget.isExceeded
                                ? AppColors.error
                                : budget.isWarning
                                    ? AppColors.warning
                                    : txtSec,
                          ),),
                    ],),
                  ],
                ),
              ),
              SizedBox(
                width: 32,
                height: 32,
                child: PopupMenuButton<String>(
                  onSelected: (v) {
                    if (v == 'edit') onEdit();
                    if (v == 'delete') onDelete();
                  },
                  color: isDark ? AppColors.cardDark : AppColors.card,
                  offset: const Offset(0, 8),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),),
                  elevation: 6,
                  itemBuilder: (_) => [
                    PopupMenuItem(
                      value: 'edit',
                      height: 40,
                      child: Row(children: [
                        const Icon(Icons.edit_rounded,
                            size: 15, color: AppColors.primary,),
                        const SizedBox(width: 8),
                        Text('Edit',
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: txtPrim,),),
                      ],),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      height: 40,
                      child: Row(children: [
                        Icon(Icons.delete_outline_rounded,
                            size: 15, color: AppColors.error,),
                        SizedBox(width: 8),
                        Text('Hapus',
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.error,),),
                      ],),
                    ),
                  ],
                  icon: Icon(Icons.more_vert_rounded,
                      color: txtHint, size: 18,),
                  padding: EdgeInsets.zero,
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // ── Progress track ───────────────────────────────────────────────
          Stack(children: [
            Container(
              height: 8,
              decoration: BoxDecoration(
                color: surfColor,
                borderRadius: BorderRadius.circular(100),
              ),
            ),
            TweenAnimationBuilder<double>(
              key: ValueKey('${budget.category}_${budget.spent}'),
              tween: Tween(begin: 0, end: pct),
              duration: const Duration(milliseconds: 700),
              curve: Curves.easeOutQuart,
              builder: (_, val, __) => FractionallySizedBox(
                widthFactor: val.clamp(0.0, 1.0),
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: progressColor,
                    borderRadius: BorderRadius.circular(100),
                    boxShadow: [
                      BoxShadow(
                        color: progressColor.withValues(alpha: 0.35),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],),

          const SizedBox(height: 11),

          // ── Amounts row ──────────────────────────────────────────────────
          Row(children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Dipakai',
                  style: TextStyle(
                      fontSize: 10,
                      color: txtHint,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.1,),),
              const SizedBox(height: 1),
              Text(
                CurrencyFormatter.formatCompact(budget.spent),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: budget.isExceeded ? AppColors.error : txtPrim,
                  letterSpacing: -0.2,
                ),
              ),
            ],),
            const Spacer(),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: progressColor.withValues(alpha: isDark ? 0.15 : 0.10),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${(pct * 100).round()}%',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: progressColor,
                ),
              ),
            ),
            const Spacer(),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text('Batas',
                  style: TextStyle(
                      fontSize: 10,
                      color: txtHint,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.1,),),
              const SizedBox(height: 1),
              Text(
                CurrencyFormatter.formatCompact(budget.limitAmount),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: txtSec,
                  letterSpacing: -0.2,
                ),
              ),
            ],),
          ],),

          // ── Warning banner ───────────────────────────────────────────────
          if (budget.isExceeded || budget.isWarning) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: progressColor.withValues(alpha: isDark ? 0.12 : 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: progressColor.withValues(alpha: 0.20), width: 1,),
              ),
              child: Row(children: [
                Icon(
                  budget.isExceeded
                      ? Icons.error_outline_rounded
                      : Icons.info_outline_rounded,
                  size: 13,
                  color: progressColor,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    budget.isExceeded
                        ? 'Budget terlampaui sebesar ${CurrencyFormatter.formatCompact(budget.spent - budget.limitAmount)}'
                        : 'Sisa ${CurrencyFormatter.formatCompact(budget.remaining)} — hati-hati pengeluaran',
                    style: TextStyle(
                      fontSize: 11,
                      color: progressColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],),
            ),
          ],
        ],
      ),
    );
  }
}