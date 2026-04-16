import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/currency_formatter.dart';

class AmountText extends StatelessWidget {
  final double amount;
  final bool isExpense;
  final double? fontSize;
  final FontWeight? fontWeight;
  final bool showSign;
  final bool compact;

  const AmountText({
    super.key,
    required this.amount,
    this.isExpense = false,
    this.fontSize,
    this.fontWeight,
    this.showSign = false,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isExpense ? AppColors.expense : AppColors.income;
    final text = showSign
        ? CurrencyFormatter.formatWithSign(amount, isExpense: isExpense)
        : (compact
            ? CurrencyFormatter.formatCompact(amount)
            : CurrencyFormatter.format(amount));

    return Text(
      text,
      style: TextStyle(
        fontSize: fontSize ?? 14,
        fontWeight: fontWeight ?? FontWeight.w600,
        color: color,
      ),
    );
  }
}