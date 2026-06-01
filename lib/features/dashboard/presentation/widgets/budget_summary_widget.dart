import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
// MonthlyComparisonCard ada di file terpisah:
export 'monthly_comparison_card.dart';

// ── Budget Summary Widget ─────────────────────────────────────────────────────

/// Mini preview 3 budget teratas untuk dashboard.
class BudgetSummaryWidget extends StatelessWidget {
  final VoidCallback? onSeeAll;
  const BudgetSummaryWidget({super.key, this.onSeeAll});

  // TODO: replace with Riverpod budget provider
  static const _demo = [
    _BudgetItem('🍔 Food', 650000, 900000, AppColors.catFood),
    _BudgetItem('🚌 Transport', 180000, 200000, AppColors.catTransport),
    _BudgetItem('🛍️ Shopping', 420000, 500000, AppColors.catShopping),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Budget',
                style: Theme.of(context).textTheme.titleMedium),
            if (onSeeAll != null)
              GestureDetector(
                onTap: onSeeAll,
                child: const Text(
                  'Lihat Semua',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        // Budget rows
        ..._demo.map((item) => _BudgetRow(item: item)),
      ],
    );
  }
}

class _BudgetRow extends StatelessWidget {
  final _BudgetItem item;
  const _BudgetRow({required this.item});

  @override
  Widget build(BuildContext context) {
    final ratio = (item.spent / item.total).clamp(0.0, 1.0);
    final isWarning = ratio >= 0.8;
    final isExceeded = ratio >= 1.0;

    final barColor = isExceeded
        ? AppColors.expense
        : isWarning
            ? AppColors.warning
            : item.color;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(item.label,
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w600)),
                  if (isWarning)
                    Padding(
                      padding: const EdgeInsets.only(left: 6),
                      child: Icon(
                        isExceeded
                            ? Icons.warning_rounded
                            : Icons.info_rounded,
                        size: 14,
                        color: isExceeded
                            ? AppColors.expense
                            : AppColors.warning,
                      ),
                    ),
                ],
              ),
              Text(
                '${CurrencyFormatter.formatCompact(item.spent)} / '
                '${CurrencyFormatter.formatCompact(item.total)}',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isExceeded
                      ? AppColors.expense
                      : AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: ratio,
              backgroundColor: barColor.withOpacity(0.12),
              valueColor: AlwaysStoppedAnimation(barColor),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }
}

class _BudgetItem {
  final String label;
  final double spent;
  final double total;
  final Color color;
  const _BudgetItem(this.label, this.spent, this.total, this.color);
}