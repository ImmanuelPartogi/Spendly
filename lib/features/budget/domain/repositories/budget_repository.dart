import '../entities/budget_entity.dart';

abstract class BudgetRepository {
  Stream<List<BudgetEntity>> watchAllBudgets();
  Future<List<BudgetEntity>> getAllBudgets();
  Future<void> setBudget(BudgetEntity budget);
  Future<void> deleteBudget(int id);
}