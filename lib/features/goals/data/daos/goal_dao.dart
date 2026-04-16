import 'package:drift/drift.dart';
import '../../../../core/database/app_database.dart';

part 'goal_dao.g.dart';

@DriftAccessor(tables: [Goals])
class GoalDao extends DatabaseAccessor<AppDatabase>
    with _$GoalDaoMixin {
  GoalDao(super.db);

  // ── Read ──────────────────────────────────────────────────────────────────

  /// Watch semua goals, diurutkan: aktif dulu (deadline terdekat), lalu selesai.
  Stream<List<Goal>> watchAllGoals() => (select(goals)
        ..orderBy([
          (g) => OrderingTerm.asc(g.isCompleted),
          (g) => OrderingTerm.asc(g.deadline),
        ]))
      .watch();

  Future<List<Goal>> getAllGoals() => (select(goals)
        ..orderBy([
          (g) => OrderingTerm.asc(g.isCompleted),
          (g) => OrderingTerm.asc(g.deadline),
        ]))
      .get();

  Future<Goal?> getGoalById(String id) =>
      (select(goals)..where((g) => g.id.equals(id))).getSingleOrNull();

  // ── Write ─────────────────────────────────────────────────────────────────

  Future<void> insertGoal(GoalsCompanion entry) =>
      into(goals).insert(entry);

  Future<void> updateGoal(String id, GoalsCompanion entry) =>
      (update(goals)..where((g) => g.id.equals(id))).write(entry);

  Future<void> deleteGoal(String id) =>
      (delete(goals)..where((g) => g.id.equals(id))).go();

  // ── Domain operations ─────────────────────────────────────────────────────

  /// Tambah dana ke goal; auto-complete jika sudah mencapai target.
  Future<void> allocateFunds(String id, double amount) async {
    final goal = await getGoalById(id);
    if (goal == null) return;

    final newAmount =
        (goal.currentAmount + amount).clamp(0.0, goal.targetAmount);
    final completed = newAmount >= goal.targetAmount;

    await updateGoal(
      id,
      GoalsCompanion(
        currentAmount: Value(newAmount),
        isCompleted: Value(completed),
      ),
    );
  }
}