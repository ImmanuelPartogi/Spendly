import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/database/database_providers.dart';
import '../../../analytics/domain/providers/analytics_providers.dart';
import '../../data/repositories/budget_repository_impl.dart';
import '../repositories/budget_repository.dart';
import '../usecases/budget_usecases.dart';
import '../entities/budget_entity.dart';

final budgetRepositoryProvider = Provider<BudgetRepository>(
    (ref) => BudgetRepositoryImpl(ref.watch(budgetDaoProvider)),);

final getBudgetsUseCaseProvider =
    Provider((ref) => GetBudgetsUseCase(ref.watch(budgetRepositoryProvider)));
final setBudgetUseCaseProvider =
    Provider((ref) => SetBudgetUseCase(ref.watch(budgetRepositoryProvider)));
final deleteBudgetUseCaseProvider =
    Provider((ref) => DeleteBudgetUseCase(ref.watch(budgetRepositoryProvider)));

final budgetListStreamProvider = StreamProvider<List<BudgetEntity>>(
    (ref) => ref.watch(getBudgetsUseCaseProvider).watch(),);

final budgetsWithSpentProvider = Provider<List<BudgetEntity>>((ref) {
  final budgets =
      ref.watch(budgetListStreamProvider).valueOrNull ?? const [];
  final categoryTotals = ref.watch(categoryBreakdownProvider);
  return [
    for (final b in budgets)
      b.copyWith(spent: categoryTotals[b.category] ?? 0),
  ];
});
