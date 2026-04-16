import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../shared/widgets/spendly_card.dart';

class BudgetSummaryCard extends StatelessWidget {
  final bool isDark;
  final double totalLimit;
  final double totalSpent;
  final int exceededCount;
  final int budgetCount;

  const BudgetSummaryCard({
    super.key,
    required this.isDark,
    required this.totalLimit,
    required this.totalSpent,
    required this.exceededCount,
    required this.budgetCount,
  });

  @override
  Widget build(BuildContext context) {
    final overallPct =
        totalLimit > 0 ? (totalSpent / totalLimit).clamp(0.0, 1.0) : 0.0;
    final diff = totalLimit - totalSpent;
    final isOver = diff < 0;
    final progressColor = isOver
        ? AppColors.error
        : overallPct >= 0.8
            ? AppColors.warning
            : AppColors.income;

    return SpendlyCard(
      gradient: AppColors.primaryGradient,
      elevated: true,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Total Budget Bulan Ini',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    CurrencyFormatter.format(totalLimit),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.6,
                      height: 1.1,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$budgetCount kategori',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          ClipRRect(
            borderRadius: BorderRadius.circular(100),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: overallPct),
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeOutQuart,
              builder: (_, val, __) => LinearProgressIndicator(
                value: val.clamp(0.0, 1.0),
                backgroundColor: Colors.white.withOpacity(0.20),
                valueColor: AlwaysStoppedAnimation<Color>(
                  isOver ? AppColors.error : Colors.white,
                ),
                minHeight: 6,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _SummaryChip(
                label: 'Terpakai',
                value: CurrencyFormatter.format(totalSpent),
                icon: Icons.arrow_upward_rounded,
                valueColor:
                    isOver ? const Color(0xFFFFB3BE) : Colors.white,
              ),
              const Spacer(),
              _SummaryChip(
                label: isOver ? 'Melebihi' : 'Sisa',
                value: isOver
                    ? '+ ${CurrencyFormatter.format(diff.abs())}'
                    : CurrencyFormatter.format(diff),
                icon: isOver
                    ? Icons.warning_amber_rounded
                    : Icons.savings_rounded,
                valueColor: isOver
                    ? const Color(0xFFFFB3BE)
                    : const Color(0xFF7EFFD4),
                alignRight: true,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color valueColor;
  final bool alignRight;

  const _SummaryChip({
    required this.label,
    required this.value,
    required this.icon,
    required this.valueColor,
    this.alignRight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (!alignRight) ...[
          Icon(icon, color: valueColor, size: 13),
          const SizedBox(width: 5),
        ],
        Column(
          crossAxisAlignment:
              alignRight ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 10,
                    fontWeight: FontWeight.w500)),
            Text(value,
                style: TextStyle(
                  color: valueColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                )),
          ],
        ),
        if (alignRight) ...[
          const SizedBox(width: 5),
          Icon(icon, color: valueColor, size: 13),
        ],
      ],
    );
  }
}