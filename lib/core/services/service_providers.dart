import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'restore_service.dart';
import '../database/database_providers.dart';

final restoreServiceProvider = Provider<RestoreService>(
  (ref) => RestoreService(
    ref.watch(transactionDaoProvider),
    ref.watch(walletDaoProvider),
    ref.watch(budgetDaoProvider),
  ),
);
