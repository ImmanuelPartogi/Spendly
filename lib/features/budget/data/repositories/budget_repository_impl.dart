import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/database/daos/budget_dao.dart';
import '../../../../core/services/sync_service.dart';
import '../../domain/entities/budget_entity.dart';
import '../../domain/repositories/budget_repository.dart';

class BudgetRepositoryImpl implements BudgetRepository {
  final BudgetDao _dao;
  BudgetRepositoryImpl(this._dao);

  @override
  Stream<List<BudgetEntity>> watchAllBudgets() =>
      _dao.watchAllBudgets().map((l) => l.map(_fromBudget).toList());

  @override
  Future<List<BudgetEntity>> getAllBudgets() async =>
      (await _dao.getAllBudgets()).map(_fromBudget).toList();

  @override
  Future<void> setBudget(BudgetEntity budget) async {
    await _dao.upsertBudget(
      BudgetsCompanion.insert(
        category: budget.category,
        limitAmount: budget.limitAmount,
        period: Value(budget.period),
        synced: const Value(false),
      ),
    );

    // Sync ke Firebase (await, update synced = true jika berhasil)
    await _uploadBudget(budget);
  }

  @override
  Future<void> deleteBudget(int id) async {
    final existing = await _dao.getBudgetById(id);
    await _dao.deleteBudget(id);

    if (existing != null) {
      _deleteBudgetRemote(existing.category);
    }
  }

  void _deleteBudgetRemote(String category) {
    SyncService.deleteBudget(category).catchError((e) {
      debugPrint('[BudgetRepo] Delete budget remote error: $e');
    });
  }

  Future<void> _uploadBudget(BudgetEntity budget) async {
    try {
      await SyncService.uploadBudget({
        'category': budget.category,
        'limitAmount': budget.limitAmount,
        'period': budget.period,
      });
      await _dao.markAsSynced([budget.category]);
      debugPrint('[BudgetRepo] Synced budget to Firebase: ${budget.category}');
    } catch (e) {
      debugPrint('[BudgetRepo] Firebase budget sync failed (will retry when online): $e');
    }
  }

  BudgetEntity _fromBudget(Budget b) => BudgetEntity(
        id: b.id,
        category: b.category,
        limitAmount: b.limitAmount,
        period: b.period,
      );
}
