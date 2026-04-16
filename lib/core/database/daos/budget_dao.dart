import 'package:drift/drift.dart';
import '../app_database.dart';

part 'budget_dao.g.dart';

@DriftAccessor(tables: [Budgets])
class BudgetDao extends DatabaseAccessor<AppDatabase> with _$BudgetDaoMixin {
  BudgetDao(super.db);

  Stream<List<Budget>> watchAllBudgets() => select(budgets).watch();
  Future<List<Budget>> getAllBudgets() => select(budgets).get();

  Future<Budget?> getBudgetByCategory(String category) => (select(budgets)
        ..where((b) => b.category.equals(category))
        ..limit(1))
      .getSingleOrNull();

  Future<void> upsertBudget(BudgetsCompanion entry) async {
    final existing = await getBudgetByCategory(entry.category.value);
    if (existing == null) {
      await into(budgets).insert(entry);
    } else {
      await (update(budgets)..where((b) => b.id.equals(existing.id)))
          .write(BudgetsCompanion(limitAmount: entry.limitAmount));
    }
  }

  Future<void> deleteBudget(int id) =>
      (delete(budgets)..where((b) => b.id.equals(id))).go();

  Future<void> deleteAll() => delete(budgets).go();
}
