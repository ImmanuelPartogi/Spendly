import 'package:flutter/foundation.dart';
import '../../../../core/database/daos/transaction_dao.dart';
import '../../../../core/database/daos/wallet_dao.dart';
import '../../../../core/services/sync_service.dart';
import '../../domain/entities/transaction_entity.dart';
import '../../domain/repositories/transaction_repository.dart';
import '../models/transaction_model.dart';

/// Concrete [TransactionRepository] backed by the local Drift database.
///
/// Wallet-balance bookkeeping is performed atomically inside the DAO methods
/// (`insertTransaction`, `updateTransactionById`, `deleteTransactionById`).
/// This layer must NOT duplicate that logic, otherwise balances would be
/// applied twice.
class TransactionRepositoryImpl implements TransactionRepository {
  final TransactionDao _dao;
  final WalletDao _walletDao;

  TransactionRepositoryImpl(this._dao, this._walletDao);

  // ── Read ──────────────────────────────────────────────────────────────────

  @override
  Stream<List<TransactionEntity>> watchAllTransactions() =>
      _dao.watchAllTransactions()
          .map((rows) => rows.map(TransactionModel.fromDrift).toList());

  @override
  Stream<List<TransactionEntity>> watchTransactionsByMonth(int year, int month) =>
      _dao.watchTransactionsByMonth(year, month)
          .map((rows) => rows.map(TransactionModel.fromDrift).toList());

  @override
  Stream<List<TransactionEntity>> watchRecentTransactions({int limit = 5}) =>
      _dao.watchRecentTransactions(limit: limit)
          .map((rows) => rows.map(TransactionModel.fromDrift).toList());

  @override
  Future<List<TransactionEntity>> getAllTransactions() async =>
      (await _dao.getAllTransactions()).map(TransactionModel.fromDrift).toList();

  @override
  Future<List<TransactionEntity>> getTransactionsByDateRange(
          DateTime start, DateTime end,) async =>
      (await _dao.getTransactionsByDateRange(start, end))
          .map(TransactionModel.fromDrift)
          .toList();

  @override
  Future<List<TransactionEntity>> getRecentTransactions({int limit = 5}) async =>
      (await _dao.getRecentTransactions(limit: limit))
          .map(TransactionModel.fromDrift)
          .toList();

  // ── Write ─────────────────────────────────────────────────────────────────

  @override
  Future<String> addTransaction(TransactionEntity tx) async {
    final id = await _dao.insertTransaction(TransactionModel.toCompanion(tx));
    _syncTransactionAndWallet(tx, id);
    return id;
  }

  @override
  Future<void> updateTransaction(String oldId, TransactionEntity newTx) async {
    await _dao.updateTransactionById(oldId, TransactionModel.toCompanion(newTx));
    _syncTransactionAndWallet(newTx, newTx.id);
  }

  @override
  Future<void> deleteTransaction(String id) async {
    final tx = await _dao.getTransactionById(id);
    await _dao.deleteTransactionById(id);

    await SyncService.deleteTransaction(id).catchError((e) {
      debugPrint('[Repo] Delete sync error: $e');
    });

    if (tx != null) {
      _uploadWalletBalance(tx.walletId);
    }
  }

  // ── Aggregations ──────────────────────────────────────────────────────────

  @override
  Future<double> getTotalByTypeAndMonth(String type, int year, int month) =>
      _dao.getTotalByTypeAndMonth(type, year, month);

  @override
  Future<Map<String, double>> getCategoryTotals(
          int year, int month, String type,) =>
      _dao.getCategoryTotals(year, month, type);

  @override
  Future<Map<int, double>> getDailyTotals(int year, int month, String type) =>
      _dao.getDailyTotals(year, month, type);

  @override
  Future<Map<int, double>> getWeekdayTotals(int year, int month, String type) =>
      _dao.getWeekdayTotals(year, month, type);

  // ── Pending sync ──────────────────────────────────────────────────────────

  Future<void> syncPending() async {
    final pending = await _dao.getPendingSync();
    if (pending.isEmpty) return;

    debugPrint('[Repo] Syncing ${pending.length} pending transactions...');

    final pendingData = pending
        .map((tx) => TransactionModel.toJson(TransactionModel.fromDrift(tx)))
        .toList();

    await SyncService.syncPendingTransactions(pendingData);

    final ids = pending.map((tx) => tx.id).toList();
    await _dao.markAsSynced(ids);
  }

  /// Recomputes a wallet's balance from scratch using all its transactions.
  ///
  /// Called after restoring from Firebase to ensure balances are consistent
  /// with the restored transaction set.
  Future<void> recalculateWalletBalance(String walletId) async {
    final allTxs = await _dao.getAllTransactions();
    final walletTxs = allTxs.where((tx) => tx.walletId == walletId);

    var balance = 0.0;
    for (final tx in walletTxs) {
      final entity = TransactionModel.fromDrift(tx);
      balance += entity.isExpense ? -entity.amount : entity.amount;
    }

    await _walletDao.updateBalance(walletId, balance);
    debugPrint('[Repo] Recalculated balance for $walletId: $balance');
  }

  // ── Private helpers ───────────────────────────────────────────────────────

  void _syncTransactionAndWallet(TransactionEntity tx, String id) {
    final data = TransactionModel.toJson(tx.copyWith(id: id));
    SyncService.uploadTransaction(data).then((_) async {
      await _dao.markAsSynced([id]);
      debugPrint('[Repo] Synced tx to Firebase: $id');
    }).catchError((e) {
      debugPrint('[Repo] Firebase tx sync failed (will retry): $e');
    });

    _uploadWalletBalance(tx.walletId);
  }

  void _uploadWalletBalance(String walletId) {
    _walletDao.getWalletById(walletId).then((wallet) {
      if (wallet == null) return;
      SyncService.uploadWallet({
        'id': wallet.id,
        'name': wallet.name,
        'balance': wallet.balance,
        'type': wallet.type,
        'colorValue': wallet.colorValue,
        'isDefault': wallet.isDefault,
      }).catchError((e) {
        debugPrint('[Repo] Firebase wallet sync failed: $e');
      });
    }).catchError((e) {
      debugPrint('[Repo] Get wallet error: $e');
    });
  }
}