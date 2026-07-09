import 'package:drift/drift.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/database/app_database.dart';
import '../../data/daos/goal_dao.dart';
import '../entities/goal_entity.dart';

// ── Mapper ────────────────────────────────────────────────────────────────────

extension GoalRowMapper on Goal {
  GoalEntity toEntity() => GoalEntity(
        id: id,
        title: title,
        emoji: emoji,
        targetAmount: targetAmount,
        currentAmount: currentAmount,
        deadline: deadline,
        color: Color(colorValue),
        isCompleted: isCompleted,
        createdAt: createdAt,
      );
}

// ── Use Cases ─────────────────────────────────────────────────────────────────

class GetGoalsUseCase {
  final GoalDao _dao;
  GetGoalsUseCase(this._dao);

  Stream<List<GoalEntity>> watch() =>
      _dao.watchAllGoals().map((list) => list.map((g) => g.toEntity()).toList());

  Future<List<GoalEntity>> getAll() async {
    final list = await _dao.getAllGoals();
    return list.map((g) => g.toEntity()).toList();
  }
}

class AddGoalUseCase {
  final GoalDao _dao;
  AddGoalUseCase(this._dao);

  Future<void> call(GoalEntity entity) => _dao.insertGoal(
        GoalsCompanion(
          id: Value(entity.id.isEmpty ? const Uuid().v4() : entity.id),
          title: Value(entity.title),
          emoji: Value(entity.emoji),
          targetAmount: Value(entity.targetAmount),
          currentAmount: Value(entity.currentAmount),
          deadline: Value(entity.deadline),
          colorValue: Value(entity.color.toARGB32()),
          isCompleted: Value(entity.isCompleted),
        ),
      );
}

class UpdateGoalUseCase {
  final GoalDao _dao;
  UpdateGoalUseCase(this._dao);

  Future<void> call(GoalEntity entity) => _dao.updateGoal(
        entity.id,
        GoalsCompanion(
          title: Value(entity.title),
          emoji: Value(entity.emoji),
          targetAmount: Value(entity.targetAmount),
          currentAmount: Value(entity.currentAmount),
          deadline: Value(entity.deadline),
          colorValue: Value(entity.color.toARGB32()),
          isCompleted: Value(entity.isCompleted),
        ),
      );
}

class DeleteGoalUseCase {
  final GoalDao _dao;
  DeleteGoalUseCase(this._dao);

  Future<void> call(String id) => _dao.deleteGoal(id);
}

class AllocateFundsUseCase {
  final GoalDao _dao;
  AllocateFundsUseCase(this._dao);

  Future<void> call(String goalId, double amount) =>
      _dao.allocateFunds(goalId, amount);
}