import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/database/database_providers.dart';
import '../usecases/recurring_usecases.dart';
import '../entities/recurring_entity.dart';

final getRecurringsUseCaseProvider = Provider<GetRecurringsUseCase>(
    (ref) => GetRecurringsUseCase(ref.watch(recurringDaoProvider)),);
final addRecurringUseCaseProvider = Provider<AddRecurringUseCase>(
    (ref) => AddRecurringUseCase(ref.watch(recurringDaoProvider)),);
final updateRecurringUseCaseProvider = Provider<UpdateRecurringUseCase>(
    (ref) => UpdateRecurringUseCase(ref.watch(recurringDaoProvider)),);
final deleteRecurringUseCaseProvider = Provider<DeleteRecurringUseCase>(
    (ref) => DeleteRecurringUseCase(ref.watch(recurringDaoProvider)),);
final toggleRecurringUseCaseProvider = Provider<ToggleRecurringUseCase>(
    (ref) => ToggleRecurringUseCase(ref.watch(recurringDaoProvider)),);

final recurringListProvider = StreamProvider<List<RecurringEntity>>(
    (ref) => ref.watch(getRecurringsUseCaseProvider).watch(),);
