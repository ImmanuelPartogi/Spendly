import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/database/database_providers.dart';
import '../usecases/goal_usecases.dart';
import '../entities/goal_entity.dart';

final getGoalsUseCaseProvider = Provider<GetGoalsUseCase>(
    (ref) => GetGoalsUseCase(ref.watch(goalDaoProvider)),);
final addGoalUseCaseProvider = Provider<AddGoalUseCase>(
    (ref) => AddGoalUseCase(ref.watch(goalDaoProvider)),);
final updateGoalUseCaseProvider = Provider<UpdateGoalUseCase>(
    (ref) => UpdateGoalUseCase(ref.watch(goalDaoProvider)),);
final deleteGoalUseCaseProvider = Provider<DeleteGoalUseCase>(
    (ref) => DeleteGoalUseCase(ref.watch(goalDaoProvider)),);
final allocateFundsUseCaseProvider = Provider<AllocateFundsUseCase>(
    (ref) => AllocateFundsUseCase(ref.watch(goalDaoProvider)),);

final goalListProvider = StreamProvider<List<GoalEntity>>(
    (ref) => ref.watch(getGoalsUseCaseProvider).watch(),);
