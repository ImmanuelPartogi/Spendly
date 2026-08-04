import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/database/database_providers.dart';
import '../../data/repositories/transaction_repository_impl.dart';
import '../repositories/transaction_repository.dart';
import '../usecases/transaction_usecases.dart';
import '../entities/transaction_entity.dart';

final transactionRepositoryImplProvider = Provider<TransactionRepositoryImpl>(
  (ref) => TransactionRepositoryImpl(
    ref.watch(transactionDaoProvider),
    ref.watch(walletDaoProvider),
  ),
);

final transactionRepositoryProvider = Provider<TransactionRepository>(
  (ref) => ref.watch(transactionRepositoryImplProvider),
);

final addTransactionUseCaseProvider = Provider(
    (ref) => AddTransactionUseCase(ref.watch(transactionRepositoryProvider)),);
final getTransactionsUseCaseProvider = Provider(
    (ref) => GetTransactionsUseCase(ref.watch(transactionRepositoryProvider)),);
final deleteTransactionUseCaseProvider = Provider((ref) =>
    DeleteTransactionUseCase(ref.watch(transactionRepositoryProvider)),);
final updateTransactionUseCaseProvider = Provider((ref) =>
    UpdateTransactionUseCase(ref.watch(transactionRepositoryProvider)),);
final calculateMonthlyUseCaseProvider = Provider((ref) =>
    CalculateMonthlySpendingUseCase(ref.watch(transactionRepositoryProvider)),);

final allTransactionsStreamProvider = StreamProvider<List<TransactionEntity>>(
  (ref) => ref.watch(transactionRepositoryProvider).watchAllTransactions(),
);

final selectedMonthProvider = StateProvider<DateTime>((ref) => DateTime.now());

final monthlyTransactionsProvider =
    StreamProvider<List<TransactionEntity>>((ref) {
  final date = ref.watch(selectedMonthProvider);
  return ref
      .watch(getTransactionsUseCaseProvider)
      .watchByMonth(date.year, date.month);
});

final recentTransactionsProvider =
    Provider<AsyncValue<List<TransactionEntity>>>((ref) {
  final allAsync = ref.watch(allTransactionsStreamProvider);
  return allAsync.whenData((all) {
    final sorted = [...all]..sort((a, b) => b.date.compareTo(a.date));
    return sorted.take(10).toList();
  });
});
