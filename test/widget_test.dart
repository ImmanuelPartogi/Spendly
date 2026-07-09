import 'package:flutter_test/flutter_test.dart';

import 'package:spendly/features/budget/domain/entities/budget_entity.dart';
import 'package:spendly/features/transactions/domain/entities/transaction_entity.dart';

void main() {
  group('BudgetEntity', () {
    test('percentage is clamped to [0.0, 1.0]', () {
      const budget = BudgetEntity(
        category: 'Food',
        limitAmount: 100,
        spent: 150,
      );
      expect(budget.percentage, 1.0);
      expect(budget.isExceeded, isTrue);
    });

    test('isWarning is true at or above 80%', () {
      const budget = BudgetEntity(
        category: 'Food',
        limitAmount: 100,
        spent: 80,
      );
      expect(budget.isWarning, isTrue);
      expect(budget.isExceeded, isFalse);
    });

    test('remaining is never negative', () {
      const budget = BudgetEntity(
        category: 'Food',
        limitAmount: 50,
        spent: 100,
      );
      expect(budget.remaining, 0.0);
    });

    test('spent is part of equality (props)', () {
      const a = BudgetEntity(category: 'Food', limitAmount: 100, spent: 20);
      const b = BudgetEntity(category: 'Food', limitAmount: 100, spent: 20);
      const c = BudgetEntity(category: 'Food', limitAmount: 100, spent: 30);

      expect(a, equals(b));
      expect(a, isNot(equals(c)));
    });

    test('copyWith preserves immutability contract', () {
      const original = BudgetEntity(category: 'Food', limitAmount: 100);
      final updated = original.copyWith(spent: 50);

      expect(original.spent, 0.0);
      expect(updated.spent, 50.0);
    });
  });

  group('TransactionEntity', () {
    final baseDate = DateTime(2024, 1, 15);

    TransactionEntity buildTransaction({
      String type = 'expense',
      String? note,
    }) =>
        TransactionEntity(
          id: 'tx-1',
          walletId: 'wallet-1',
          amount: 25,
          type: type,
          category: 'Food',
          note: note,
          date: baseDate,
          createdAt: baseDate,
        );

    test('isExpense is true for "expense" type', () {
      expect(buildTransaction(type: 'expense').isExpense, isTrue);
    });

    test('isExpense is false for "income" type', () {
      expect(buildTransaction(type: 'income').isExpense, isFalse);
    });

    test('isIncome is true for "income" type', () {
      expect(buildTransaction(type: 'income').isIncome, isTrue);
    });

    test('copyWith creates a new instance with merged fields', () {
      final original = buildTransaction(note: null);
      final updated = original.copyWith(note: 'With friends');

      expect(updated.note, 'With friends');
      expect(updated.amount, original.amount);
      expect(updated.id, original.id);
    });
  });
}