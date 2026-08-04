import 'package:flutter_test/flutter_test.dart';
import 'package:spendly/features/budget/domain/entities/budget_entity.dart';

void main() {
  group('Budget Warning & Threshold Unit Tests', () {
    test('isWarning triggers at exactly 80% spending threshold', () {
      const budget80 = BudgetEntity(
        category: 'Makanan & Minuman',
        limitAmount: 1000000,
        spent: 800000,
      );

      expect(budget80.percentage, 0.8);
      expect(budget80.isWarning, isTrue);
      expect(budget80.isExceeded, isFalse);
    });

    test('isWarning is false below 80% spending threshold', () {
      const budget79 = BudgetEntity(
        category: 'Transportasi',
        limitAmount: 1000000,
        spent: 790000,
      );

      expect(budget79.percentage, 0.79);
      expect(budget79.isWarning, isFalse);
      expect(budget79.isExceeded, isFalse);
    });

    test('isExceeded triggers when spending exceeds 100% limit', () {
      const budgetExceeded = BudgetEntity(
        category: 'Hiburan',
        limitAmount: 500000,
        spent: 600000,
      );

      expect(budgetExceeded.percentage, 1.0); // Clamped percentage
      expect(budgetExceeded.isWarning, isTrue); // Warning also true when exceeded
      expect(budgetExceeded.isExceeded, isTrue);
      expect(budgetExceeded.remaining, 0.0); // Remaining never negative
    });

    test('Budget summary calculations aggregate total limit, spent, and remaining', () {
      const budgets = [
        BudgetEntity(category: 'Makanan', limitAmount: 1000000, spent: 500000),
        BudgetEntity(category: 'Transportasi', limitAmount: 500000, spent: 400000),
        BudgetEntity(category: 'Belanja', limitAmount: 800000, spent: 900000),
      ];

      final totalLimit = budgets.fold<double>(0, (sum, b) => sum + b.limitAmount);
      final totalSpent = budgets.fold<double>(0, (sum, b) => sum + b.spent);
      final warningCount = budgets.where((b) => b.isWarning).length;

      expect(totalLimit, 2300000);
      expect(totalSpent, 1800000);
      expect(warningCount, 2); // Transportasi (80%) and Belanja (>100%)
    });
  });
}
