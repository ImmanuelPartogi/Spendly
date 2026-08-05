import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/financial_health_calculator.dart';
import '../../../budget/domain/providers/budget_providers.dart';
import '../../../transactions/domain/entities/transaction_entity.dart';
import '../../../transactions/domain/providers/transaction_providers.dart';

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
        return 'period_this_week'.tr();
      case AnalyticsPeriod.thisMonth:
        return 'period_this_month'.tr();
      case AnalyticsPeriod.threeMonths:
        return 'period_3months'.tr();
      case AnalyticsPeriod.sixMonths:
        return 'period_6months'.tr();
      case AnalyticsPeriod.thisYear:
        return 'period_this_year'.tr();
      case AnalyticsPeriod.custom:
        return 'period_custom'.tr();
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
              (tx) => !tx.date.isBefore(startDay) && !tx.date.isAfter(endDay),)
          .toList(),);
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

final financialHealthScoreProvider = Provider<FinancialHealthResult>((ref) {
  final income = ref.watch(monthlyIncomeProvider);
  final expense = ref.watch(monthlyExpenseProvider);
  final budgets = ref.watch(budgetsWithSpentProvider);
  return FinancialHealthCalculator.calculate(
    income: income,
    expense: expense,
    budgets: budgets,
  );
});

final sixMonthsTrendProvider =
    FutureProvider<List<({DateTime date, double income, double expense})>>((ref) async {
  ref.watch(monthlyTransactionsProvider);
  final now = DateTime.now();
  final repo = ref.read(transactionRepositoryProvider);
  final result = <({DateTime date, double income, double expense})>[];

  for (int i = 5; i >= 0; i--) {
    final d = DateTime(now.year, now.month - i, 1);
    final totalIncome = await repo.getTotalByTypeAndMonth('income', d.year, d.month);
    final totalExpense = await repo.getTotalByTypeAndMonth('expense', d.year, d.month);
    result.add((date: d, income: totalIncome, expense: totalExpense));
  }

  return result;
});
