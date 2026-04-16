import '../entities/transaction_entity.dart';

abstract class TransactionRepository {
  Stream<List<TransactionEntity>> watchAllTransactions();
  Stream<List<TransactionEntity>> watchTransactionsByMonth(int year, int month);
  Stream<List<TransactionEntity>> watchRecentTransactions({int limit = 5});
  Future<List<TransactionEntity>> getAllTransactions();
  Future<List<TransactionEntity>> getTransactionsByDateRange(DateTime start, DateTime end);
  Future<List<TransactionEntity>> getRecentTransactions({int limit = 5});
  Future<String> addTransaction(TransactionEntity transaction);
  Future<void> updateTransaction(String oldId, TransactionEntity newTx);
  Future<void> deleteTransaction(String id);
  Future<double> getTotalByTypeAndMonth(String type, int year, int month);
  Future<Map<String, double>> getCategoryTotals(int year, int month, String type);
  Future<Map<int, double>> getDailyTotals(int year, int month, String type);
  Future<Map<int, double>> getWeekdayTotals(int year, int month, String type);
}