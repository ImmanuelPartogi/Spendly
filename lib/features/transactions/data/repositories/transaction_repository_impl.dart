import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/database/daos/transaction_dao.dart';
import '../../../../core/database/daos/wallet_dao.dart';
import '../../../../core/services/sync_service.dart';
import '../../domain/entities/transaction_entity.dart';
import '../../domain/repositories/transaction_repository.dart';
import '../models/transaction_model.dart';

class TransactionRepositoryImpl implements TransactionRepository {
  final TransactionDao _dao;
  final WalletDao _walletDao;

  TransactionRepositoryImpl(this._dao, this._walletDao);

  // ── Read ──────────────────────────────────────────────────────────────────

  @override
  Stream<List<TransactionEntity>> watchAllTransactions() =>
      _dao.watchAllTransactions()
          .map((l) => l.map(TransactionModel.fromDrift).toList());

  @override
  Stream<List<TransactionEntity>> watchTransactionsByMonth(
          int year, int month) =>
      _dao.watchTransactionsByMonth(year, month)
          .map((l) => l.map(TransactionModel.fromDrift).toList());

  @override
  Stream<List<TransactionEntity>> watchRecentTransactions(
          {int limit = 5}) =>
      _dao.watchRecentTransactions(limit: limit)
          .map((l) => l.map(TransactionModel.fromDrift).toList());

  @override
  Future<List<TransactionEntity>> getAllTransactions() async =>
      (await _dao.getAllTransactions())
          .map(TransactionModel.fromDrift)
          .toList();

  @override
  Future<List<TransactionEntity>> getTransactionsByDateRange(
      DateTime start, DateTime end) async =>
      (await _dao.getTransactionsByDateRange(start, end))
          .map(TransactionModel.fromDrift)
          .toList();

  @override
  Future<List<TransactionEntity>> getRecentTransactions(
          {int limit = 5}) async =>
      (await _dao.getRecentTransactions(limit: limit))
          .map(TransactionModel.fromDrift)
          .toList();

  // ── Write ─────────────────────────────────────────────────────────────────

  @override
  Future<String> addTransaction(TransactionEntity tx) async {
    final id = await _dao.insertTransaction(
      TransactionModel.toCompanion(tx),
    );

    // ✅ FIX: Update wallet balance di local DB
    await _applyBalanceDelta(
      walletId: tx.walletId,
      amount: tx.amount,
      isExpense: tx.isExpense,
    );

    _syncTransactionAndWallet(tx, id);
    return id;
  }

  @override
  Future<void> updateTransaction(
      String oldId, TransactionEntity newTx) async {
    // ✅ FIX: Ambil transaksi lama dulu untuk reverse effect-nya
    final oldRow = await _dao.getTransactionById(oldId);

    await _dao.updateTransactionById(
      oldId,
      TransactionModel.toCompanion(newTx),
    );

    if (oldRow != null) {
      final oldTx = TransactionModel.fromDrift(oldRow);
      final wallet = await _walletDao.getWalletById(newTx.walletId);
      if (wallet != null) {
        // Reverse efek transaksi lama
        final reversal = oldTx.isExpense ? oldTx.amount : -oldTx.amount;
        // Terapkan efek transaksi baru
        final delta = newTx.isExpense ? -newTx.amount : newTx.amount;
        final newBalance = wallet.balance + reversal + delta;
        await _walletDao.updateBalance(newTx.walletId, newBalance);
        debugPrint('[Repo] Balance updated: ${wallet.balance} → $newBalance');
      }
    }

    _syncTransactionAndWallet(newTx, newTx.id);
  }

  @override
  Future<void> deleteTransaction(String id) async {
    final tx = await _dao.getTransactionById(id);
    await _dao.deleteTransactionById(id);

    SyncService.deleteTransaction(id).catchError((e) {
      debugPrint('[Repo] Delete sync error: $e');
    });

    if (tx != null) {
      // ✅ FIX: Reverse efek transaksi yang dihapus
      final entity = TransactionModel.fromDrift(tx);
      final wallet = await _walletDao.getWalletById(tx.walletId);
      if (wallet != null) {
        // Reverse: jika expense, kembalikan uang; jika income, kurangi
        final reversal = entity.isExpense ? entity.amount : -entity.amount;
        final newBalance = wallet.balance + reversal;
        await _walletDao.updateBalance(tx.walletId, newBalance);
        debugPrint('[Repo] Balance after delete: ${wallet.balance} → $newBalance');
      }

      _uploadWalletBalance(tx.walletId);
    }
  }

  // ── Aggregations ──────────────────────────────────────────────────────────

  @override
  Future<double> getTotalByTypeAndMonth(
          String type, int year, int month) =>
      _dao.getTotalByTypeAndMonth(type, year, month);

  @override
  Future<Map<String, double>> getCategoryTotals(
          int year, int month, String type) =>
      _dao.getCategoryTotals(year, month, type);

  @override
  Future<Map<int, double>> getDailyTotals(
          int year, int month, String type) =>
      _dao.getDailyTotals(year, month, type);

  @override
  Future<Map<int, double>> getWeekdayTotals(
          int year, int month, String type) =>
      _dao.getWeekdayTotals(year, month, type);

  // ── Pending sync ──────────────────────────────────────────────────────────

  Future<void> syncPending() async {
    final pending = await _dao.getPendingSync();
    if (pending.isEmpty) return;

    debugPrint('[Repo] Syncing ${pending.length} pending transactions...');

    final pendingData = pending
        .map((tx) => TransactionModel.toJson(
            TransactionModel.fromDrift(tx)))
        .toList();

    await SyncService.syncPendingTransactions(pendingData);

    final ids = pending.map((tx) => tx.id).toList();
    await _dao.markAsSynced(ids);
  }

  /// ✅ Recalculate wallet balance dari semua transaksi yang ada di local DB.
  /// Panggil ini saat restore dari Firebase agar balance konsisten.
  Future<void> recalculateWalletBalance(String walletId) async {
    final allTxs = await _dao.getAllTransactions();
    final walletTxs = allTxs.where((tx) => tx.walletId == walletId);

    double balance = 0.0;
    for (final tx in walletTxs) {
      final entity = TransactionModel.fromDrift(tx);
      if (entity.isExpense) {
        balance -= entity.amount;
      } else {
        balance += entity.amount;
      }
    }

    await _walletDao.updateBalance(walletId, balance);
    debugPrint('[Repo] Recalculated balance for $walletId: $balance');
  }

  // ── Private helpers ───────────────────────────────────────────────────────

  Future<void> _applyBalanceDelta({
    required String walletId,
    required double amount,
    required bool isExpense,
  }) async {
    final wallet = await _walletDao.getWalletById(walletId);
    if (wallet == null) {
      debugPrint('[Repo] Wallet not found: $walletId');
      return;
    }
    final delta = isExpense ? -amount : amount;
    final newBalance = wallet.balance + delta;
    await _walletDao.updateBalance(walletId, newBalance);
    debugPrint('[Repo] Balance updated: ${wallet.balance} → $newBalance');
  }

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