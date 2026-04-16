import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/utils/currency_formatter.dart';

class ComparisonSummaryRow extends StatelessWidget {
  final double income;
  final double expense;
  final double savings;
  final bool isDark;

  const ComparisonSummaryRow({
    super.key,
    required this.income,
    required this.expense,
    required this.savings,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final isDeficit = savings < 0;
    final savColor = isDeficit ? AppColors.expense : AppColors.income;
    final rate = income > 0 ? ((savings / income) * 100).abs() : 0.0;
    final card = isDark ? AppColors.cardDark : AppColors.card;
    final bdr = isDark ? AppColors.borderDark : AppColors.border;
    final sec = isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;

    return Row(children: [
      Expanded(child: _Tile(
        label: 'Total Masuk', value: income,
        color: AppColors.income, icon: Icons.south_rounded,
        card: card, bdr: bdr, sec: sec,
      )),
      const SizedBox(width: 10),
      Expanded(child: _Tile(
        label: 'Total Keluar', value: expense,
        color: AppColors.expense, icon: Icons.north_rounded,
        card: card, bdr: bdr, sec: sec,
      )),
      const SizedBox(width: 10),
      Expanded(child: _Tile(
        label: isDeficit ? 'Defisit' : 'Surplus',
        value: savings.abs(), color: savColor,
        icon: isDeficit ? Icons.trending_down_rounded : Icons.trending_up_rounded,
        badge: '${rate.toStringAsFixed(0)}%',
        card: card, bdr: bdr, sec: sec,
      )),
    ]);
  }
}

class _Tile extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  final IconData icon;
  final String? badge;
  final Color card;
  final Color bdr;
  final Color sec;

  const _Tile({
    required this.label, required this.value, required this.color,
    required this.icon, required this.card, required this.bdr,
    required this.sec, this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: bdr, width: 0.5),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 30, height: 30,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 15),
            ),
            if (badge != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(badge!,
                    style: TextStyle(
                        fontSize: 9, fontWeight: FontWeight.w700, color: color)),
              ),
          ],
        ),
        const SizedBox(height: 10),
        TweenAnimationBuilder<double>(
          key: ValueKey(value),
          tween: Tween(begin: 0, end: value),
          duration: const Duration(milliseconds: 700),
          curve: Curves.easeOutQuart,
          builder: (_, v, __) => Text(
            CurrencyFormatter.formatCompact(v),
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: color,
                letterSpacing: -0.4),
          ),
        ),
        const SizedBox(height: 2),
        Text(label,
            style: TextStyle(
                fontSize: 10, color: sec, fontWeight: FontWeight.w500)),
      ]),
    );
  }
}