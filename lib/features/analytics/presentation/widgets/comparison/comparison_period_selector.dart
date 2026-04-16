import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../screens/income_expense_comparison_screen.dart';

class ComparisonPeriodSelector extends StatelessWidget {
  final ComparisonPeriod selected;
  final bool isDark;
  final ValueChanged<ComparisonPeriod> onChanged;

  const ComparisonPeriodSelector({
    super.key,
    required this.selected,
    required this.isDark,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final surf = isDark ? AppColors.surfaceDark : AppColors.surface;
    final bdr = isDark ? AppColors.borderDark : AppColors.border;
    final sec = isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: surf,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: bdr, width: 0.5),
      ),
      child: Row(
        children: ComparisonPeriod.values.map((p) {
          final on = p == selected;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(p),
              child: AnimatedContainer(
                duration: kDurationFast,
                curve: kCurveDefault,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: on ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: on
                      ? [
                          BoxShadow(
                              color: AppColors.primary.withOpacity(0.25),
                              blurRadius: 8,
                              offset: const Offset(0, 3))
                        ]
                      : null,
                ),
                child: Center(
                  child: Text(p.label,
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: on ? FontWeight.w700 : FontWeight.w500,
                          color: on ? Colors.white : sec)),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}