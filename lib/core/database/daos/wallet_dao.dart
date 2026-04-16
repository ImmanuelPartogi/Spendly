import 'package:drift/drift.dart';
import '../app_database.dart';

part 'wallet_dao.g.dart';

@DriftAccessor(tables: [Wallets])
class WalletDao extends DatabaseAccessor<AppDatabase>
    with _$WalletDaoMixin {
  WalletDao(super.db);

  // ── Read ──────────────────────────────────────────────────────────────────

  Stream<List<Wallet>> watchAllWallets() => (select(wallets)
        ..orderBy([
          (w) => OrderingTerm.desc(w.isDefault),
          (w) => OrderingTerm.asc(w.name),
        ]))
      .watch();

  Future<List<Wallet>> getAllWallets() => (select(wallets)
        ..orderBy([
          (w) => OrderingTerm.desc(w.isDefault),
          (w) => OrderingTerm.asc(w.name),
        ]))
      .get();

  Future<Wallet?> getWalletById(String id) =>
      (select(wallets)..where((w) => w.id.equals(id))).getSingleOrNull();

  Future<double> getTotalBalance() async {
    final all = await getAllWallets();
    double total = 0.0;
    for (final wallet in all) {
      total += wallet.balance;
    }
    return total;
  }

  // ── Write ─────────────────────────────────────────────────────────────────

  Future<void> insertWallet(WalletsCompanion entry) =>
      into(wallets).insert(entry);

  /// Insert or update berdasarkan primary key id — digunakan untuk restore
  Future<void> upsertWallet(WalletsCompanion entry) =>
      into(wallets).insertOnConflictUpdate(entry);

  Future<void> updateWallet(String id, WalletsCompanion entry) =>
      (update(wallets)..where((w) => w.id.equals(id))).write(entry);

  Future<void> deleteWallet(String id) =>
      (delete(wallets)..where((w) => w.id.equals(id))).go();

  Future<void> updateBalance(String id, double newBalance) =>
      (update(wallets)..where((w) => w.id.equals(id)))
          .write(WalletsCompanion(balance: Value(newBalance)));

  // ── Transfer ──────────────────────────────────────────────────────────────

  Future<void> transferFunds({
    required String fromId,
    required String toId,
    required double amount,
  }) async {
    await db.transaction(() async {
      final from = await getWalletById(fromId);
      final to = await getWalletById(toId);

      if (from == null || to == null) {
        throw Exception('Wallet tidak ditemukan');
      }
      if (from.balance < amount) {
        throw Exception('Saldo tidak mencukupi');
      }

      await updateBalance(fromId, from.balance - amount);
      await updateBalance(toId, to.balance + amount);
    });
  }

  Future<void> deleteAll() => delete(wallets).go();
}