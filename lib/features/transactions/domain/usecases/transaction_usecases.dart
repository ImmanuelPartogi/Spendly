import '../entities/transaction_entity.dart';
import '../repositories/transaction_repository.dart';

class AddTransactionUseCase {
  final TransactionRepository repository;
  AddTransactionUseCase(this.repository);
  Future<String> call(TransactionEntity tx) => repository.addTransaction(tx);
}

class GetTransactionsUseCase {
  final TransactionRepository repository;
  GetTransactionsUseCase(this.repository);
  Stream<List<TransactionEntity>> watchAll() => repository.watchAllTransactions();
  Stream<List<TransactionEntity>> watchByMonth(int year, int month) => repository.watchTransactionsByMonth(year, month);
  Stream<List<TransactionEntity>> watchRecent({int limit = 5}) => repository.watchRecentTransactions(limit: limit);
  Future<List<TransactionEntity>> getAll() => repository.getAllTransactions();
}

class DeleteTransactionUseCase {
  final TransactionRepository repository;
  DeleteTransactionUseCase(this.repository);
  Future<void> call(String id) => repository.deleteTransaction(id);
}

class UpdateTransactionUseCase {
  final TransactionRepository repository;
  UpdateTransactionUseCase(this.repository);
  Future<void> call(String oldId, TransactionEntity newTx) => repository.updateTransaction(oldId, newTx);
}

class CalculateMonthlySpendingUseCase {
  final TransactionRepository repository;
  CalculateMonthlySpendingUseCase(this.repository);
  Future<double> getTotalExpense(int year, int month) => repository.getTotalByTypeAndMonth('expense', year, month);
  Future<double> getTotalIncome(int year, int month) => repository.getTotalByTypeAndMonth('income', year, month);
  Future<Map<String, double>> getCategoryBreakdown(int year, int month) => repository.getCategoryTotals(year, month, 'expense');
  Future<Map<int, double>> getDailySpending(int year, int month) => repository.getDailyTotals(year, month, 'expense');
  Future<Map<int, double>> getWeekdaySpending(int year, int month) => repository.getWeekdayTotals(year, month, 'expense');
}