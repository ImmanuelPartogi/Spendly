import 'package:flutter/material.dart';
import '../../features/budget/domain/entities/budget_entity.dart';
import '../theme/app_colors.dart';

class FinancialHealthResult {
  final int score;
  final String statusKey;
  final Color color;

  const FinancialHealthResult({
    required this.score,
    required this.statusKey,
    required this.color,
  });
}

class FinancialHealthCalculator {
  FinancialHealthCalculator._();

  static FinancialHealthResult calculate({
    required double income,
    required double expense,
    required List<BudgetEntity> budgets,
  }) {
    // 1. Expense to Income Factor (60% Weight)
    double ratioScore = 100.0;
    if (income > 0) {
      final ratio = expense / income;
      if (ratio <= 0.5) {
        ratioScore = 100.0;
      } else if (ratio <= 0.8) {
        ratioScore = 80.0;
      } else if (ratio <= 1.0) {
        ratioScore = 50.0;
      } else {
        ratioScore = (50.0 - (ratio - 1.0) * 100).clamp(0.0, 50.0);
      }
    } else if (expense > 0) {
      ratioScore = 20.0;
    }

    // 2. Budget Adherence Factor (40% Weight)
    double budgetScore = 100.0;
    if (budgets.isNotEmpty) {
      final safeCount = budgets.where((b) => !b.isExceeded).length;
      budgetScore = (safeCount / budgets.length) * 100.0;
    }

    // Composite Score
    final totalScore = ((ratioScore * 0.6) + (budgetScore * 0.4)).round().clamp(0, 100);

    // Classification
    if (totalScore >= 80) {
      return FinancialHealthResult(
        score: totalScore,
        statusKey: 'financial_healthy',
        color: AppColors.income,
      );
    } else if (totalScore >= 50) {
      return FinancialHealthResult(
        score: totalScore,
        statusKey: 'financial_caution',
        color: AppColors.warning,
      );
    } else {
      return FinancialHealthResult(
        score: totalScore,
        statusKey: 'financial_overspending',
        color: AppColors.expense,
      );
    }
  }
}
