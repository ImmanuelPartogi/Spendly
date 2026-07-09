import 'dart:async';

import 'package:drift/drift.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/database/daos/wallet_dao.dart';
import '../../../../core/database/daos/transaction_dao.dart';
import '../../../../core/services/sync_service.dart';
import '../../../transactions/data/models/transaction_model.dart';
import '../../../transactions/domain/entities/transaction_entity.dart';
import '../entities/wallet_entity.dart';

// ── Mapper ────────────────────────────────────────────────────────────────────

extension WalletRowMapper on Wallet {
  WalletEntity toEntity() => WalletEntity(
        id: id,
        name: name,
        balance: balance,
        type: WalletType.values.firstWhere(
          (t) => t.name == type,
          orElse: () => WalletType.cash,
        ),
        color: Color(colorValue),
        isDefault: isDefault,
        createdAt: createdAt,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'balance': balance,
        'type': type,
        'colorValue': colorValue,
        'isDefault': isDefault,
      };
}

// ── Use Cases ─────────────────────────────────────────────────────────────────

class GetWalletsUseCase {
  final WalletDao _dao;
  GetWalletsUseCase(this._dao);

  Stream<List<WalletEntity>> watch() =>
      _dao.watchAllWallets().map((list) => list.map((w) => w.toEntity()).toList());

  Future<List<WalletEntity>> getAll() async {
    final list = await _dao.getAllWallets();
    return list.map((w) => w.toEntity()).toList();
  }
}

class AddWalletUseCase {
  final WalletDao _walletDao;
  final TransactionDao _txDao;

  // ✅ Sekarang butuh 2 DAO: wallet + transaction (untuk opening balance)
  AddWalletUseCase(this._walletDao, this._txDao);

  Future<String> call(WalletEntity entity) async {
    final id = entity.id.isEmpty ? const Uuid().v4() : entity.id;

    // 1. Simpan wallet ke Drift (balance tetap sesuai entity)
    await _walletDao.insertWallet(
      WalletsCompanion.insert(
        id: id,
        name: entity.name,
        balance: Value(entity.balance),
        type: Value(entity.type.name),
        colorValue: Value(entity.color.toARGB32()),
        isDefault: Value(entity.isDefault),
        synced: const Value(false),
      ),
    );

    // 2. ✅ Jika ada saldo awal, buat transaksi "Saldo Awal" sebagai income
    // Ini agar totalBalanceProvider (income - expense) ikut menghitung saldo awal
    if (entity.balance > 0) {
      final openingTx = TransactionEntity(
        id: const Uuid().v4(),
        walletId: id,
        amount: entity.balance,
        type: 'income',
        category: 'Saldo Awal',
        note: 'Saldo awal ${entity.name}',
        date: DateTime.now(),
        createdAt: DateTime.now(),
      );

      await _txDao.insertTransaction(TransactionModel.toCompanion(openingTx));

      // Sync opening balance transaction ke Firebase
      unawaited(
        SyncService.uploadTransaction(
          TransactionModel.toJson(openingTx),
        ).catchError((e) {
          debugPrint('[Wallet] Opening balance tx sync failed: $e');
        }),
      );

      debugPrint('[Wallet] Opening balance tx created: ${entity.balance}');
    }

    // 3. Upload wallet ke Firebase
    _uploadWalletToFirebase(id, entity);

    return id;
  }

  void _uploadWalletToFirebase(String id, WalletEntity entity) {
    SyncService.uploadWallet({
      'id': id,
      'name': entity.name,
      'balance': entity.balance,
      'type': entity.type.name,
      'colorValue': entity.color.toARGB32(),
      'isDefault': entity.isDefault,
    }).then((_) {
      debugPrint('[Wallet] Synced to Firebase: $id');
    }).catchError((e) {
      debugPrint('[Wallet] Firebase sync failed (will retry): $e');
    });
  }
}

class UpdateWalletUseCase {
  final WalletDao _dao;
  UpdateWalletUseCase(this._dao);

  Future<void> call(WalletEntity entity) async {
    // 1. Update Drift local DB
    await _dao.updateWallet(
      entity.id,
      WalletsCompanion(
        name: Value(entity.name),
        balance: Value(entity.balance),
        type: Value(entity.type.name),
        colorValue: Value(entity.color.toARGB32()),
        isDefault: Value(entity.isDefault),
        synced: const Value(false),
      ),
    );

    // 2. ✅ Upload ke Firebase
    unawaited(
      SyncService.uploadWallet({
        'id': entity.id,
        'name': entity.name,
        'balance': entity.balance,
        'type': entity.type.name,
        'colorValue': entity.color.toARGB32(),
        'isDefault': entity.isDefault,
      }).catchError((e) {
        debugPrint('[Wallet] Update sync failed: $e');
      }),
    );
  }
}

class DeleteWalletUseCase {
  final WalletDao _dao;
  DeleteWalletUseCase(this._dao);

  Future<void> call(String id) async {
    // 1. Hapus dari Drift local DB
    await _dao.deleteWallet(id);

    // 2. ✅ Tandai deleted di Firebase
    unawaited(
      SyncService.deleteWallet(id).catchError((e) {
        debugPrint('[Wallet] Delete sync failed: $e');
      }),
    );
  }
}

class TransferFundsUseCase {
  final WalletDao _dao;
  TransferFundsUseCase(this._dao);

  Future<void> call({
    required String fromId,
    required String toId,
    required double amount,
  }) async {
    // 1. Transfer di Drift local DB
    await _dao.transferFunds(fromId: fromId, toId: toId, amount: amount);

    // 2. ✅ Sync kedua wallet ke Firebase setelah transfer
    final wallets = await _dao.getAllWallets();
    for (final w in wallets.where((w) => w.id == fromId || w.id == toId)) {
      unawaited(
        SyncService.uploadWallet({
          'id': w.id,
          'name': w.name,
          'balance': w.balance,
          'type': w.type,
          'colorValue': w.colorValue,
          'isDefault': w.isDefault,
        }).catchError((e) {
          debugPrint('[Wallet] Transfer sync failed for ${w.id}: $e');
        }),
      );
    }
  }
}