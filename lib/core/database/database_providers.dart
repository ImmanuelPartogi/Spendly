import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app_database.dart';
import 'daos/transaction_dao.dart';
import 'daos/wallet_dao.dart';
import 'daos/budget_dao.dart';
import '../../features/goals/data/daos/goal_dao.dart';
import '../../features/recurring/data/daos/recurring_dao.dart';

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

final transactionDaoProvider = Provider<TransactionDao>(
    (ref) => TransactionDao(ref.watch(databaseProvider)),);
final walletDaoProvider =
    Provider<WalletDao>((ref) => WalletDao(ref.watch(databaseProvider)));
final budgetDaoProvider =
    Provider<BudgetDao>((ref) => BudgetDao(ref.watch(databaseProvider)));
final goalDaoProvider =
    Provider<GoalDao>((ref) => GoalDao(ref.watch(databaseProvider)));
final recurringDaoProvider =
    Provider<RecurringDao>((ref) => RecurringDao(ref.watch(databaseProvider)));
