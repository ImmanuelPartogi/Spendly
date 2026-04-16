import 'package:drift/drift.dart';
import '../../../../core/database/app_database.dart';

part 'recurring_dao.g.dart';

@DriftAccessor(tables: [Recurrings])
class RecurringDao extends DatabaseAccessor<AppDatabase>
    with _$RecurringDaoMixin {
  RecurringDao(super.db);

  // ── Read ──────────────────────────────────────────────────────────────────

  /// Watch semua recurring: aktif dulu, lalu urutkan berdasarkan nextDue.
  Stream<List<Recurring>> watchAllRecurrings() => (select(recurrings)
        ..orderBy([
          (r) => OrderingTerm.desc(r.isActive),
          (r) => OrderingTerm.asc(r.nextDue),
        ]))
      .watch();

  Future<List<Recurring>> getAllRecurrings() => (select(recurrings)
        ..orderBy([
          (r) => OrderingTerm.desc(r.isActive),
          (r) => OrderingTerm.asc(r.nextDue),
        ]))
      .get();

  Future<Recurring?> getRecurringById(String id) =>
      (select(recurrings)..where((r) => r.id.equals(id)))
          .getSingleOrNull();

  // ── Write ─────────────────────────────────────────────────────────────────

  Future<void> insertRecurring(RecurringsCompanion entry) =>
      into(recurrings).insert(entry);

  Future<void> updateRecurring(String id, RecurringsCompanion entry) =>
      (update(recurrings)..where((r) => r.id.equals(id))).write(entry);

  Future<void> deleteRecurring(String id) =>
      (delete(recurrings)..where((r) => r.id.equals(id))).go();

  Future<void> toggleActive(String id, {required bool isActive}) =>
      (update(recurrings)..where((r) => r.id.equals(id)))
          .write(RecurringsCompanion(isActive: Value(isActive)));
}