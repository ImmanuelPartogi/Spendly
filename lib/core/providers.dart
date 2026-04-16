import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spendly/features/auth/domain/services/auth_service.dart';
import 'database/app_database.dart';
import 'database/daos/transaction_dao.dart';
import 'database/daos/wallet_dao.dart';
import 'database/daos/budget_dao.dart';
import 'services/sync_service.dart';
import 'services/restore_service.dart';
import '../features/transactions/data/repositories/transaction_repository_impl.dart';
import '../features/transactions/domain/repositories/transaction_repository.dart';
import '../features/transactions/domain/usecases/transaction_usecases.dart';
import '../features/transactions/domain/entities/transaction_entity.dart';
import '../features/budget/data/repositories/budget_repository_impl.dart';
import '../features/budget/domain/repositories/budget_repository.dart';
import '../features/budget/domain/usecases/budget_usecases.dart';
import '../features/budget/domain/entities/budget_entity.dart';
import '../features/insight/domain/services/insight_engine.dart';
import '../features/goals/data/daos/goal_dao.dart';
import '../features/goals/domain/usecases/goal_usecases.dart';
import '../features/goals/domain/entities/goal_entity.dart';
import '../features/recurring/data/daos/recurring_dao.dart';
import '../features/recurring/domain/usecases/recurring_usecases.dart';
import '../features/recurring/domain/entities/recurring_entity.dart';
import '../features/wallet/domain/usecases/wallet_usecases.dart';
import '../features/wallet/domain/entities/wallet_entity.dart';

// ─── Database ─────────────────────────────────────────────────────────────────

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

// ─── DAOs ─────────────────────────────────────────────────────────────────────

final transactionDaoProvider = Provider<TransactionDao>(
    (ref) => TransactionDao(ref.watch(databaseProvider)));
final walletDaoProvider =
    Provider<WalletDao>((ref) => WalletDao(ref.watch(databaseProvider)));
final budgetDaoProvider =
    Provider<BudgetDao>((ref) => BudgetDao(ref.watch(databaseProvider)));
final goalDaoProvider =
    Provider<GoalDao>((ref) => GoalDao(ref.watch(databaseProvider)));
final recurringDaoProvider =
    Provider<RecurringDao>((ref) => RecurringDao(ref.watch(databaseProvider)));

// ─── Repositories ─────────────────────────────────────────────────────────────

final transactionRepositoryImplProvider = Provider<TransactionRepositoryImpl>(
  (ref) => TransactionRepositoryImpl(
    ref.watch(transactionDaoProvider),
    ref.watch(walletDaoProvider),
  ),
);

final transactionRepositoryProvider = Provider<TransactionRepository>(
  (ref) => ref.watch(transactionRepositoryImplProvider),
);

final budgetRepositoryProvider = Provider<BudgetRepository>(
    (ref) => BudgetRepositoryImpl(ref.watch(budgetDaoProvider)));

// ─── Sync / Restore Service ───────────────────────────────────────────────────
// Note: Restore functionality is implemented in SyncService
// RestoreService was refactored, this provider is kept for backwards compatibility

final restoreServiceProvider = Provider<RestoreService>(
  (ref) => RestoreService(
    ref.watch(transactionDaoProvider),
    ref.watch(walletDaoProvider),
    ref.watch(budgetDaoProvider),
  ),
);

// ─── Auth & PIN State ─────────────────────────────────────────────────────────
//
// Semua provider ini dibuat sebagai StateNotifier/StateProvider agar bisa
// di-invalidate setelah RestoreService.downloadAll() + AuthService.restorePin()
// selesai, sehingga AppGate langsung bereaksi tanpa perlu restart app.

/// Dipakai AppGate untuk memutuskan apakah perlu tampil PinScreen.
/// Setelah restorePin() selesai, panggil:
///   ref.invalidate(pinEnabledProvider)
final pinEnabledProvider = FutureProvider<bool>((ref) async {
  return AuthService.isPinEnabled();
});

/// Dipakai SettingsScreen untuk toggle biometric.
/// Setelah setBiometricEnabled() dipanggil, invalidate provider ini.
final biometricEnabledProvider = FutureProvider<bool>((ref) async {
  return AuthService.isBiometricEnabled();
});

/// True jika hardware biometric tersedia di device.
/// Tidak perlu di-invalidate — nilai ini statis per device.
final biometricAvailableProvider = FutureProvider<bool>((ref) async {
  return AuthService.isBiometricAvailable();
});

/// Dipakai AppGate/OnboardingFlow: apakah user belum menyelesaikan setup PIN.
/// Setelah setup selesai (setPinSetupPending(false)), invalidate provider ini.
final pinSetupPendingProvider = FutureProvider<bool>((ref) async {
  return AuthService.isPinSetupPending();
});

// ─── Use Cases — Transactions ──────────────────────────────────────────────────

final addTransactionUseCaseProvider = Provider(
    (ref) => AddTransactionUseCase(ref.watch(transactionRepositoryProvider)));
final getTransactionsUseCaseProvider = Provider(
    (ref) => GetTransactionsUseCase(ref.watch(transactionRepositoryProvider)));
final deleteTransactionUseCaseProvider = Provider((ref) =>
    DeleteTransactionUseCase(ref.watch(transactionRepositoryProvider)));
final updateTransactionUseCaseProvider = Provider((ref) =>
    UpdateTransactionUseCase(ref.watch(transactionRepositoryProvider)));
final calculateMonthlyUseCaseProvider = Provider((ref) =>
    CalculateMonthlySpendingUseCase(ref.watch(transactionRepositoryProvider)));

// ─── Use Cases — Budget ────────────────────────────────────────────────────────

final getBudgetsUseCaseProvider =
    Provider((ref) => GetBudgetsUseCase(ref.watch(budgetRepositoryProvider)));
final setBudgetUseCaseProvider =
    Provider((ref) => SetBudgetUseCase(ref.watch(budgetRepositoryProvider)));
final deleteBudgetUseCaseProvider =
    Provider((ref) => DeleteBudgetUseCase(ref.watch(budgetRepositoryProvider)));

// ─── Use Cases — Wallet ────────────────────────────────────────────────────────

final getWalletsUseCaseProvider = Provider<GetWalletsUseCase>(
    (ref) => GetWalletsUseCase(ref.watch(walletDaoProvider)));
final addWalletUseCaseProvider = Provider<AddWalletUseCase>(
    (ref) => AddWalletUseCase(
          ref.watch(walletDaoProvider),
          ref.watch(transactionDaoProvider),
        ));
final updateWalletUseCaseProvider = Provider<UpdateWalletUseCase>(
    (ref) => UpdateWalletUseCase(ref.watch(walletDaoProvider)));
final deleteWalletUseCaseProvider = Provider<DeleteWalletUseCase>(
    (ref) => DeleteWalletUseCase(ref.watch(walletDaoProvider)));
final transferFundsUseCaseProvider = Provider<TransferFundsUseCase>(
    (ref) => TransferFundsUseCase(ref.watch(walletDaoProvider)));

// ─── Use Cases — Goals ─────────────────────────────────────────────────────────

final getGoalsUseCaseProvider = Provider<GetGoalsUseCase>(
    (ref) => GetGoalsUseCase(ref.watch(goalDaoProvider)));
final addGoalUseCaseProvider = Provider<AddGoalUseCase>(
    (ref) => AddGoalUseCase(ref.watch(goalDaoProvider)));
final updateGoalUseCaseProvider = Provider<UpdateGoalUseCase>(
    (ref) => UpdateGoalUseCase(ref.watch(goalDaoProvider)));
final deleteGoalUseCaseProvider = Provider<DeleteGoalUseCase>(
    (ref) => DeleteGoalUseCase(ref.watch(goalDaoProvider)));
final allocateFundsUseCaseProvider = Provider<AllocateFundsUseCase>(
    (ref) => AllocateFundsUseCase(ref.watch(goalDaoProvider)));

// ─── Use Cases — Recurring ─────────────────────────────────────────────────────

final getRecurringsUseCaseProvider = Provider<GetRecurringsUseCase>(
    (ref) => GetRecurringsUseCase(ref.watch(recurringDaoProvider)));
final addRecurringUseCaseProvider = Provider<AddRecurringUseCase>(
    (ref) => AddRecurringUseCase(ref.watch(recurringDaoProvider)));
final updateRecurringUseCaseProvider = Provider<UpdateRecurringUseCase>(
    (ref) => UpdateRecurringUseCase(ref.watch(recurringDaoProvider)));
final deleteRecurringUseCaseProvider = Provider<DeleteRecurringUseCase>(
    (ref) => DeleteRecurringUseCase(ref.watch(recurringDaoProvider)));
final toggleRecurringUseCaseProvider = Provider<ToggleRecurringUseCase>(
    (ref) => ToggleRecurringUseCase(ref.watch(recurringDaoProvider)));

// ─── Insight ───────────────────────────────────────────────────────────────────

final insightEngineProvider = Provider((ref) => InsightEngine(
    ref.watch(transactionRepositoryProvider),
    ref.watch(budgetRepositoryProvider)));

// ─── Streams ───────────────────────────────────────────────────────────────────

final walletListProvider = StreamProvider<List<WalletEntity>>(
    (ref) => ref.watch(getWalletsUseCaseProvider).watch());
final goalListProvider = StreamProvider<List<GoalEntity>>(
    (ref) => ref.watch(getGoalsUseCaseProvider).watch());
final recurringListProvider = StreamProvider<List<RecurringEntity>>(
    (ref) => ref.watch(getRecurringsUseCaseProvider).watch());
final budgetListStreamProvider = StreamProvider<List<BudgetEntity>>(
    (ref) => ref.watch(getBudgetsUseCaseProvider).watch());

/// Single source of truth untuk semua transaksi.
final allTransactionsStreamProvider = StreamProvider<List<TransactionEntity>>(
  (ref) => ref.watch(transactionRepositoryProvider).watchAllTransactions(),
);

// ─── Navigation ────────────────────────────────────────────────────────────────

final selectedMonthProvider = StateProvider<DateTime>((ref) => DateTime.now());

final monthlyTransactionsProvider =
    StreamProvider<List<TransactionEntity>>((ref) {
  final date = ref.watch(selectedMonthProvider);
  return ref
      .watch(getTransactionsUseCaseProvider)
      .watchByMonth(date.year, date.month);
});

/// Derive dari allTransactionsStreamProvider agar selalu sinkron dengan
/// seluruh data (termasuk data hasil restore dari Firebase).
final recentTransactionsProvider =
    Provider<AsyncValue<List<TransactionEntity>>>((ref) {
  final allAsync = ref.watch(allTransactionsStreamProvider);
  return allAsync.whenData((all) {
    final sorted = [...all]..sort((a, b) => b.date.compareTo(a.date));
    return sorted.take(10).toList();
  });
});

// ─── Monthly Stats (reactive) ──────────────────────────────────────────────────

/// Balance dihitung dari semua transaksi (income - expense) agar selalu
/// akurat setelah restore, tanpa bergantung pada wallet.balance di DB.
final totalBalanceProvider = Provider<double>((ref) {
  final allAsync = ref.watch(allTransactionsStreamProvider);

  // Fallback sementara saat stream masih loading
  if (allAsync.isLoading) {
    final wallets = ref.watch(walletListProvider).valueOrNull ?? [];
    return wallets.fold(0.0, (sum, w) => sum + w.balance);
  }

  final allTxs = allAsync.valueOrNull ?? [];
  final income = allTxs
      .where((t) => !t.isExpense)
      .fold(0.0, (sum, t) => sum + t.amount);
  final expense = allTxs
      .where((t) => t.isExpense)
      .fold(0.0, (sum, t) => sum + t.amount);
  return income - expense;
});

final monthlyExpenseProvider = Provider<double>((ref) {
  final txs = ref.watch(monthlyTransactionsProvider).valueOrNull ?? [];
  return txs.where((t) => t.isExpense).fold(0.0, (sum, t) => sum + t.amount);
});

final monthlyIncomeProvider = Provider<double>((ref) {
  final txs = ref.watch(monthlyTransactionsProvider).valueOrNull ?? [];
  return txs.where((t) => !t.isExpense).fold(0.0, (sum, t) => sum + t.amount);
});

final categoryBreakdownProvider = Provider<Map<String, double>>((ref) {
  final txs = ref.watch(monthlyTransactionsProvider).valueOrNull ?? [];
  final result = <String, double>{};
  for (final tx in txs.where((t) => t.isExpense)) {
    result[tx.category] = (result[tx.category] ?? 0) + tx.amount;
  }
  final entries = result.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  return Map.fromEntries(entries);
});

final dailySpendingProvider = Provider<Map<int, double>>((ref) {
  final txs = ref.watch(monthlyTransactionsProvider).valueOrNull ?? [];
  final result = <int, double>{};
  for (final tx in txs.where((t) => t.isExpense)) {
    result[tx.date.day] = (result[tx.date.day] ?? 0) + tx.amount;
  }
  return result;
});

final weekdaySpendingProvider = Provider<Map<int, double>>((ref) {
  final txs = ref.watch(monthlyTransactionsProvider).valueOrNull ?? [];
  final result = <int, double>{1: 0, 2: 0, 3: 0, 4: 0, 5: 0, 6: 0, 7: 0};
  for (final tx in txs.where((t) => t.isExpense)) {
    result[tx.date.weekday] = (result[tx.date.weekday] ?? 0) + tx.amount;
  }
  return result;
});

final budgetsWithSpentProvider = Provider<List<BudgetEntity>>((ref) {
  final budgets = List<BudgetEntity>.from(
    ref.watch(budgetListStreamProvider).valueOrNull ?? [],
  );
  final categoryTotals = ref.watch(categoryBreakdownProvider);
  for (final b in budgets) {
    b.spent = categoryTotals[b.category] ?? 0;
  }
  return budgets;
});

final monthlySpendingProvider =
    FutureProvider<Map<String, List<double>>>((ref) async {
  ref.watch(monthlyTransactionsProvider);
  final now = DateTime.now();
  final result = <String, List<double>>{};
  for (int i = 2; i >= 0; i--) {
    final d = DateTime(now.year, now.month - i);
    final breakdown = await ref
        .read(calculateMonthlyUseCaseProvider)
        .getCategoryBreakdown(d.year, d.month);
    breakdown.forEach((category, amount) {
      result.putIfAbsent(category, () => []).add(amount);
    });
  }
  return result;
});

final insightsProvider = FutureProvider((ref) async {
  ref.watch(monthlyTransactionsProvider);
  return ref.watch(insightEngineProvider).generateInsights();
});

// ─── Analytics Providers ───────────────────────────────────────────────────────

enum AnalyticsPeriod {
  thisWeek,
  thisMonth,
  threeMonths,
  sixMonths,
  thisYear,
  custom,
}

extension AnalyticsPeriodLabel on AnalyticsPeriod {
  String get label {
    switch (this) {
      case AnalyticsPeriod.thisWeek:
        return 'Minggu ini';
      case AnalyticsPeriod.thisMonth:
        return 'Bulan ini';
      case AnalyticsPeriod.threeMonths:
        return '3 Bulan';
      case AnalyticsPeriod.sixMonths:
        return '6 Bulan';
      case AnalyticsPeriod.thisYear:
        return 'Tahun ini';
      case AnalyticsPeriod.custom:
        return 'Custom';
    }
  }
}

final analyticsPeriodProvider =
    StateProvider<AnalyticsPeriod>((ref) => AnalyticsPeriod.thisMonth);

final analyticsCustomRangeProvider =
    StateProvider<({DateTime start, DateTime end})?>((ref) => null);

final analyticsDateRangeProvider =
    Provider<({DateTime start, DateTime end})>((ref) {
  final period = ref.watch(analyticsPeriodProvider);
  final customRange = ref.watch(analyticsCustomRangeProvider);
  final now = DateTime.now();
  switch (period) {
    case AnalyticsPeriod.thisWeek:
      final monday = now.subtract(Duration(days: now.weekday - 1));
      return (
        start: DateTime(monday.year, monday.month, monday.day),
        end: now,
      );
    case AnalyticsPeriod.thisMonth:
      return (start: DateTime(now.year, now.month, 1), end: now);
    case AnalyticsPeriod.threeMonths:
      return (start: DateTime(now.year, now.month - 2, 1), end: now);
    case AnalyticsPeriod.sixMonths:
      return (start: DateTime(now.year, now.month - 5, 1), end: now);
    case AnalyticsPeriod.thisYear:
      return (start: DateTime(now.year, 1, 1), end: now);
    case AnalyticsPeriod.custom:
      return customRange ?? (start: DateTime(now.year, now.month, 1), end: now);
  }
});

final analyticsTransactionsProvider =
    StreamProvider<List<TransactionEntity>>((ref) {
  final range = ref.watch(analyticsDateRangeProvider);
  final startDay =
      DateTime(range.start.year, range.start.month, range.start.day);
  final endDay =
      DateTime(range.end.year, range.end.month, range.end.day, 23, 59, 59);
  return ref.watch(transactionRepositoryProvider).watchAllTransactions().map(
      (list) => list
          .where(
              (tx) => !tx.date.isBefore(startDay) && !tx.date.isAfter(endDay))
          .toList());
});

final analyticsExpenseProvider = Provider<double>((ref) {
  final txs = ref.watch(analyticsTransactionsProvider).valueOrNull ?? [];
  return txs.where((t) => t.isExpense).fold(0.0, (s, t) => s + t.amount);
});

final analyticsIncomeProvider = Provider<double>((ref) {
  final txs = ref.watch(analyticsTransactionsProvider).valueOrNull ?? [];
  return txs.where((t) => !t.isExpense).fold(0.0, (s, t) => s + t.amount);
});

final analyticsCategoryBreakdownProvider = Provider<Map<String, double>>((ref) {
  final txs = ref.watch(analyticsTransactionsProvider).valueOrNull ?? [];
  final result = <String, double>{};
  for (final tx in txs.where((t) => t.isExpense)) {
    result[tx.category] = (result[tx.category] ?? 0) + tx.amount;
  }
  final entries = result.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  return Map.fromEntries(entries);
});

final analyticsDailySpendingProvider = Provider<Map<String, double>>((ref) {
  final txs = ref.watch(analyticsTransactionsProvider).valueOrNull ?? [];
  final result = <String, double>{};
  for (final tx in txs.where((t) => t.isExpense)) {
    final key = '${tx.date.year}-${tx.date.month.toString().padLeft(2, '0')}-'
        '${tx.date.day.toString().padLeft(2, '0')}';
    result[key] = (result[key] ?? 0) + tx.amount;
  }
  return result;
});

final analyticsMonthlySpendingProvider = Provider<Map<String, double>>((ref) {
  final txs = ref.watch(analyticsTransactionsProvider).valueOrNull ?? [];
  final result = <String, double>{};
  for (final tx in txs.where((t) => t.isExpense)) {
    final key = '${tx.date.year}-${tx.date.month.toString().padLeft(2, '0')}';
    result[key] = (result[key] ?? 0) + tx.amount;
  }
  return result;
});

final analyticsWeekdaySpendingProvider = Provider<Map<int, double>>((ref) {
  final txs = ref.watch(analyticsTransactionsProvider).valueOrNull ?? [];
  final result = <int, double>{1: 0, 2: 0, 3: 0, 4: 0, 5: 0, 6: 0, 7: 0};
  for (final tx in txs.where((t) => t.isExpense)) {
    result[tx.date.weekday] = (result[tx.date.weekday] ?? 0) + tx.amount;
  }
  return result;
});

// ─── UI State ──────────────────────────────────────────────────────────────────

final bottomNavIndexProvider = StateProvider<int>((ref) => 0);
final selectedPeriodProvider = StateProvider<String>((ref) => 'Monthly');

// Sinyal ke AppGate: restore sedang berjalan atau selesai
final restoreReadyProvider = StateProvider<bool>((ref) => false);