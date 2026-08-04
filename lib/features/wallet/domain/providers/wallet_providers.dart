import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/database/database_providers.dart';
import '../../../transactions/domain/providers/transaction_providers.dart';
import '../usecases/wallet_usecases.dart';
import '../entities/wallet_entity.dart';

final getWalletsUseCaseProvider = Provider<GetWalletsUseCase>(
    (ref) => GetWalletsUseCase(ref.watch(walletDaoProvider)),);
final addWalletUseCaseProvider = Provider<AddWalletUseCase>(
    (ref) => AddWalletUseCase(
          ref.watch(walletDaoProvider),
          ref.watch(transactionDaoProvider),
        ),);
final updateWalletUseCaseProvider = Provider<UpdateWalletUseCase>(
    (ref) => UpdateWalletUseCase(ref.watch(walletDaoProvider)),);
final deleteWalletUseCaseProvider = Provider<DeleteWalletUseCase>(
    (ref) => DeleteWalletUseCase(ref.watch(walletDaoProvider)),);
final transferFundsUseCaseProvider = Provider<TransferFundsUseCase>(
    (ref) => TransferFundsUseCase(ref.watch(walletDaoProvider)),);

final walletListProvider = StreamProvider<List<WalletEntity>>(
    (ref) => ref.watch(getWalletsUseCaseProvider).watch(),);

final totalBalanceProvider = Provider<double>((ref) {
  final allAsync = ref.watch(allTransactionsStreamProvider);

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
