import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../transactions/domain/providers/transaction_providers.dart';
import '../../../budget/domain/providers/budget_providers.dart';
import '../services/insight_engine.dart';

final insightEngineProvider = Provider((ref) => InsightEngine(
    ref.watch(transactionRepositoryProvider),
    ref.watch(budgetRepositoryProvider),),);

final insightsProvider = FutureProvider((ref) async {
  ref.watch(monthlyTransactionsProvider);
  return ref.watch(insightEngineProvider).generateInsights();
});
