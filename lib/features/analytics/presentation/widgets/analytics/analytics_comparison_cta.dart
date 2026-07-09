import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../screens/income_expense_comparison_screen.dart';

class AnalyticsComparisonCta extends StatelessWidget {
  final bool isDark;

  const AnalyticsComparisonCta({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final txtPrim = isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;
    final txtSec =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => const IncomeExpenseComparisonScreen(),),
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 16, 12, 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.primary.withValues(alpha: isDark ? 0.14 : 0.08),
              AppColors.accentPurple.withValues(alpha: isDark ? 0.10 : 0.05),
            ],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.22), width: 0.5,),
        ),
        child: Row(children: [
          // Icon
          Container(
            width: 46, height: 46,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [
                AppColors.primary.withValues(alpha: 0.18),
                AppColors.accentPurple.withValues(alpha: 0.14),
              ],),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.compare_arrows_rounded,
                color: AppColors.primary, size: 22,),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Analisis Perbandingan',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: txtPrim,
                        letterSpacing: -0.2,),),
                const SizedBox(height: 3),
                Text('Lihat perbandingan lengkap pemasukan vs pengeluaran per periode, kategori, dan tren tabungan',
                    style: TextStyle(fontSize: 11, color: txtSec, height: 1.4),),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 30, height: 30,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(9),
            ),
            child: const Icon(Icons.arrow_forward_ios_rounded,
                color: Colors.white, size: 13,),
          ),
        ],),
      ),
    );
  }
}