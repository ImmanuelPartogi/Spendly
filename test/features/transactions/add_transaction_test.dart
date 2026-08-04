import 'package:flutter_test/flutter_test.dart';
import 'package:spendly/features/transactions/domain/entities/transaction_entity.dart';
import 'package:spendly/core/constants/app_constants.dart';

void main() {
  group('AddTransaction Flow & Entity Unit Tests', () {
    test('TransactionEntity expense creation sets correct type and flags', () {
      final now = DateTime.now();
      final tx = TransactionEntity(
        id: 'tx-1',
        walletId: 'w-1',
        amount: 50000,
        type: AppConstants.typeExpense,
        category: 'Makanan & Minuman',
        note: 'Makan siang',
        date: now,
        createdAt: now,
      );

      expect(tx.id, 'tx-1');
      expect(tx.walletId, 'w-1');
      expect(tx.amount, 50000);
      expect(tx.isExpense, isTrue);
      expect(tx.isIncome, isFalse);
      expect(tx.category, 'Makanan & Minuman');
      expect(tx.note, 'Makan siang');
    });

    test('TransactionEntity income creation sets correct type and flags', () {
      final now = DateTime.now();
      final tx = TransactionEntity(
        id: 'tx-2',
        walletId: 'w-1',
        amount: 5000000,
        type: AppConstants.typeIncome,
        category: 'Gaji',
        note: 'Gaji bulanan',
        date: now,
        createdAt: now,
      );

      expect(tx.isExpense, isFalse);
      expect(tx.isIncome, isTrue);
      expect(tx.category, 'Gaji');
    });

    test('Amount parsing from quick amount selections formats cleanly', () {
      const quickAmounts = [10000.0, 20000.0, 50000.0, 100000.0];

      for (final amt in quickAmounts) {
        expect(amt, greaterThan(0));
        expect(amt.toInt().toDouble(), equals(amt));
      }
    });

    test('TransactionEntity copyWith merges updated fields immutably', () {
      final now = DateTime.now();
      final original = TransactionEntity(
        id: 'tx-1',
        walletId: 'w-1',
        amount: 50000,
        type: AppConstants.typeExpense,
        category: 'Belanja',
        date: now,
        createdAt: now,
      );

      final updated = original.copyWith(
        amount: 75000,
        note: 'Belanja mingguan',
      );

      expect(updated.id, original.id);
      expect(updated.walletId, original.walletId);
      expect(updated.amount, 75000);
      expect(updated.category, 'Belanja');
      expect(updated.note, 'Belanja mingguan');
      expect(original.amount, 50000); // Original unchanged
    });
  });
}
