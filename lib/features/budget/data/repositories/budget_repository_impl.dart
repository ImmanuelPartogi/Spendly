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
    await _dao.upsertBudget(BudgetsCompanion.insert(
      category: budget.category,
      limitAmount: budget.limitAmount,
      period: Value(budget.period),
    ),);

    // Sync ke Firebase
    _uploadBudget(budget);
  }

  @override
  Future<void> deleteBudget(int id) => _dao.deleteBudget(id);

  void _uploadBudget(BudgetEntity budget) {
    SyncService.uploadBudget({
      'category': budget.category,
      'limitAmount': budget.limitAmount,
      'period': budget.period,
    }).catchError((e) {
      debugPrint('[BudgetRepo] Upload budget error: $e');
    });
  }

  BudgetEntity _fromBudget(Budget b) => BudgetEntity(
        id: b.id,
        category: b.category,
        limitAmount: b.limitAmount,
        period: b.period,
      );
}