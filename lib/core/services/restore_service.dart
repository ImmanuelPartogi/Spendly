import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:spendly/core/database/app_database.dart';
import '../database/daos/transaction_dao.dart';
import '../database/daos/wallet_dao.dart';
import '../database/daos/budget_dao.dart';
import 'sync_service.dart';

class RestoreService {
  final TransactionDao _txDao;
  final WalletDao      _walletDao;
  final BudgetDao      _budgetDao;

  RestoreService(this._txDao, this._walletDao, this._budgetDao);

  // ─── Clear data lokal ─────────────────────────────────────────────────────

  Future<void> clearLocalData() async {
    debugPrint('[Restore] Clearing local data...');
    await _txDao.deleteAll();
    await _walletDao.deleteAll();
    await _budgetDao.deleteAll();
    debugPrint('[Restore] Local data cleared');
  }

  // ─── Restore dari Firebase ────────────────────────────────────────────────
  //
  // Mengembalikan data transaksi, wallet, dan budget dari Firebase.
  // PIN TIDAK di-restore dari Firebase karena PIN hanya disimpan lokal.

  Future<void> restoreFromFirebase() async {
    debugPrint('[Restore] Starting restore from Firebase...');

    await clearLocalData();

    final result = await SyncService.downloadAll();

    // Restore wallets
    for (final data in result.wallets) {
      try {
        await _walletDao.upsertWallet(WalletsCompanion(
          id:         Value(data['id'] as String),
          name:       Value(data['name'] as String),
          balance:    const Value(0.0),
          type:       Value(data['type'] as String? ?? 'cash'),
          colorValue: Value(data['colorValue'] as int? ?? 0xFF00C48C),
          isDefault:  Value(data['isDefault'] as bool? ?? false),
          synced:     const Value(true),
        ));
      } catch (e) {
        debugPrint('[Restore] Wallet error (${data['id']}): $e');
      }
    }

    // Restore transactions
    for (final data in result.transactions) {
      try {
        await _txDao.insertTransactionRaw(TransactionsCompanion(
          id:        Value(data['id'] as String),
          walletId:  Value(data['walletId'] as String),
          amount:    Value((data['amount'] as num).toDouble()),
          type:      Value(data['type'] as String),
          category:  Value(data['category'] as String),
          note:      Value(data['note'] as String?),
          date:      Value(_parseDate(data['date'])),
          createdAt: Value(_parseDate(data['createdAt'])),
          synced:    const Value(true),
          isLocked:  const Value(false),
        ));
      } catch (e) {
        debugPrint('[Restore] Transaction error (${data['id']}): $e');
      }
    }

    // Restore budgets
    for (final data in result.budgets) {
      try {
        await _budgetDao.upsertBudget(BudgetsCompanion.insert(
          category:    data['category'] as String,
          limitAmount: (data['limitAmount'] as num).toDouble(),
          period:      Value(data['period'] as String? ?? 'monthly'),
        ));
      } catch (e) {
        debugPrint('[Restore] Budget error (${data['category']}): $e');
      }
    }

    debugPrint('[Restore] Done — tx:${result.transactions.length} '
        'wallets:${result.wallets.length} '
        'budgets:${result.budgets.length}');

    await recalculateBalances();
    await _syncUnsyncedWallets();
  }

  // ─── Recalculate balance ──────────────────────────────────────────────────

  Future<void> recalculateBalances() async {
    final allTx = await _txDao.getAllTransactions();
    if (allTx.isEmpty) return;
    final balanceMap = <String, double>{};
    for (final tx in allTx) {
      final cur = balanceMap[tx.walletId] ?? 0.0;
      balanceMap[tx.walletId] =
          tx.type == 'income' ? cur + tx.amount : cur - tx.amount;
    }
    for (final e in balanceMap.entries) {
      await _walletDao.updateBalance(e.key, e.value);
    }
  }

  // ─── Sync wallet lokal ke Firebase ───────────────────────────────────────

  Future<void> _syncUnsyncedWallets() async {
    try {
      final all = await _walletDao.getAllWallets();
      for (final w in all) {
        await SyncService.uploadWallet({
          'id': w.id, 'name': w.name, 'balance': w.balance,
          'type': w.type, 'colorValue': w.colorValue, 'isDefault': w.isDefault,
        });
      }
      debugPrint('[Restore] Synced ${all.length} wallet(s) to Firebase');
    } catch (e) {
      debugPrint('[Restore] Wallet sync error: $e');
    }
  }

  DateTime _parseDate(dynamic value) {
    if (value is String) return DateTime.parse(value);
    if (value != null && value.runtimeType.toString() == 'Timestamp') {
      return (value as dynamic).toDate() as DateTime;
    }
    return DateTime.now();
  }
}