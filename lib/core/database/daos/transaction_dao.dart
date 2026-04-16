import 'package:drift/drift.dart';
import '../app_database.dart';

part 'transaction_dao.g.dart';

@DriftAccessor(tables: [Transactions, Wallets])
class TransactionDao extends DatabaseAccessor<AppDatabase>
    with _$TransactionDaoMixin {
  TransactionDao(super.db);

  // ── Read ──────────────────────────────────────────────────────────────────

  Stream<List<Transaction>> watchAllTransactions() =>
      (select(transactions)
            ..orderBy([(t) => OrderingTerm.desc(t.date)]))
          .watch();

  Future<List<Transaction>> getAllTransactions() =>
      (select(transactions)
            ..orderBy([(t) => OrderingTerm.desc(t.date)]))
          .get();

  Stream<List<Transaction>> watchTransactionsByMonth(int year, int month) {
    final start = DateTime(year, month, 1);
    final end = DateTime(year, month + 1, 0, 23, 59, 59);
    return (select(transactions)
          ..where((t) =>
              t.date.isBiggerOrEqualValue(start) &
              t.date.isSmallerOrEqualValue(end))
          ..orderBy([(t) => OrderingTerm.desc(t.date)]))
        .watch();
  }

  Future<List<Transaction>> getTransactionsByDateRange(
          DateTime start, DateTime end) =>
      (select(transactions)
            ..where((t) =>
                t.date.isBiggerOrEqualValue(start) &
                t.date.isSmallerOrEqualValue(end))
            ..orderBy([(t) => OrderingTerm.desc(t.date)]))
          .get();

  Stream<List<Transaction>> watchRecentTransactions({int limit = 5}) =>
      (select(transactions)
            ..orderBy([(t) => OrderingTerm.desc(t.date)])
            ..limit(limit))
          .watch();

  Future<List<Transaction>> getRecentTransactions({int limit = 5}) =>
      (select(transactions)
            ..orderBy([(t) => OrderingTerm.desc(t.date)])
            ..limit(limit))
          .get();

  Future<Transaction?> getTransactionById(String id) =>
      (select(transactions)..where((t) => t.id.equals(id)))
          .getSingleOrNull();

  Future<List<Transaction>> getPendingSync() =>
      (select(transactions)..where((t) => t.synced.equals(false))).get();

  // ── Write ─────────────────────────────────────────────────────────────────

  Future<String> insertTransaction(TransactionsCompanion entry) async {
    await into(transactions).insert(entry);
    final tx = await (select(transactions)
          ..where((t) => t.id.equals(entry.id.value)))
        .getSingle();
    final wallet = await (select(wallets)
          ..where((w) => w.id.equals(tx.walletId)))
        .getSingle();

    double newBalance = wallet.balance;
    final amount = tx.amount;
    if (tx.type == 'income') {
      newBalance += amount;
    } else {
      newBalance -= amount;
    }
    await (update(wallets)..where((w) => w.id.equals(wallet.id)))
        .write(WalletsCompanion(balance: Value(newBalance)));

    return tx.id;
  }

  /// Insert langsung tanpa menyesuaikan saldo wallet — digunakan untuk restore
  Future<void> insertTransactionRaw(TransactionsCompanion entry) =>
      into(transactions).insertOnConflictUpdate(entry);

  Future<void> deleteTransactionById(String id) async {
    final tx = await (select(transactions)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    if (tx == null) return;

    final wallet = await (select(wallets)
          ..where((w) => w.id.equals(tx.walletId)))
        .getSingle();
    double balance = wallet.balance;
    final amount = tx.amount;
    if (tx.type == 'income') {
      balance -= amount;
    } else {
      balance += amount;
    }
    await (update(wallets)..where((w) => w.id.equals(wallet.id)))
        .write(WalletsCompanion(balance: Value(balance)));
    await (delete(transactions)..where((t) => t.id.equals(id))).go();
  }

  Future<void> updateTransactionById(
      String oldId, TransactionsCompanion newEntry) async {
    final oldTx = await (select(transactions)
          ..where((t) => t.id.equals(oldId)))
        .getSingleOrNull();
    if (oldTx == null) return;

    final wallet = await (select(wallets)
          ..where((w) => w.id.equals(oldTx.walletId)))
        .getSingle();
    double balance = wallet.balance;
    final oldAmount = oldTx.amount;
    if (oldTx.type == 'income') {
      balance -= oldAmount;
    } else {
      balance += oldAmount;
    }
    final newAmount = newEntry.amount.value;
    final newType = newEntry.type.value;
    if (newType == 'income') {
      balance += newAmount;
    } else {
      balance -= newAmount;
    }
    await (update(wallets)..where((w) => w.id.equals(wallet.id)))
        .write(WalletsCompanion(balance: Value(balance)));
    await (update(transactions)..where((t) => t.id.equals(oldId)))
        .write(newEntry);
  }

  Future<void> markAsSynced(List<String> ids) async {
    if (ids.isEmpty) return;
    await (update(transactions)..where((t) => t.id.isIn(ids)))
        .write(const TransactionsCompanion(synced: Value(true)));
  }

  Future<void> lockTransaction(String id) async {
    await (update(transactions)..where((t) => t.id.equals(id)))
        .write(const TransactionsCompanion(isLocked: Value(true)));
  }

  // ── Aggregations ──────────────────────────────────────────────────────────

  Future<double> getTotalByTypeAndMonth(
      String type, int year, int month) async {
    final start = DateTime(year, month, 1);
    final end = DateTime(year, month + 1, 0, 23, 59, 59);
    final results = await (select(transactions)
          ..where((t) =>
              t.type.equals(type) &
              t.date.isBiggerOrEqualValue(start) &
              t.date.isSmallerOrEqualValue(end)))
        .get();
    return results.fold<double>(0.0, (sum, t) => sum + t.amount);
  }

  Future<Map<String, double>> getCategoryTotals(
      int year, int month, String type) async {
    final start = DateTime(year, month, 1);
    final end = DateTime(year, month + 1, 0, 23, 59, 59);
    final list = await (select(transactions)
          ..where((t) =>
              t.type.equals(type) &
              t.date.isBiggerOrEqualValue(start) &
              t.date.isSmallerOrEqualValue(end)))
        .get();
    final result = <String, double>{};
    for (final tx in list) {
      result[tx.category] = (result[tx.category] ?? 0) + tx.amount;
    }
    return result;
  }

  Future<Map<int, double>> getDailyTotals(
      int year, int month, String type) async {
    final start = DateTime(year, month, 1);
    final end = DateTime(year, month + 1, 0, 23, 59, 59);
    final list = await (select(transactions)
          ..where((t) =>
              t.type.equals(type) &
              t.date.isBiggerOrEqualValue(start) &
              t.date.isSmallerOrEqualValue(end)))
        .get();
    final result = <int, double>{};
    for (final tx in list) {
      result[tx.date.day] = (result[tx.date.day] ?? 0) + tx.amount;
    }
    return result;
  }

  Future<Map<int, double>> getWeekdayTotals(
      int year, int month, String type) async {
    final start = DateTime(year, month, 1);
    final end = DateTime(year, month + 1, 0, 23, 59, 59);
    final list = await (select(transactions)
          ..where((t) =>
              t.type.equals(type) &
              t.date.isBiggerOrEqualValue(start) &
              t.date.isSmallerOrEqualValue(end)))
        .get();
    final result = <int, double>{
      1: 0, 2: 0, 3: 0, 4: 0, 5: 0, 6: 0, 7: 0,
    };
    for (final tx in list) {
      result[tx.date.weekday] =
          (result[tx.date.weekday] ?? 0) + tx.amount;
    }
    return result;
  }

  Future<void> deleteAll() => delete(transactions).go();
}