import '../entities/budget_entity.dart';
import '../repositories/budget_repository.dart';

class GetBudgetsUseCase {
  final BudgetRepository repository;
  GetBudgetsUseCase(this.repository);
  Stream<List<BudgetEntity>> watch() => repository.watchAllBudgets();
  Future<List<BudgetEntity>> getAll() => repository.getAllBudgets();
}

class SetBudgetUseCase {
  final BudgetRepository repository;
  SetBudgetUseCase(this.repository);
  Future<void> call(BudgetEntity budget) => repository.setBudget(budget);
}

class DeleteBudgetUseCase {
  final BudgetRepository repository;
  DeleteBudgetUseCase(this.repository);
  Future<void> call(int id) => repository.deleteBudget(id);
}