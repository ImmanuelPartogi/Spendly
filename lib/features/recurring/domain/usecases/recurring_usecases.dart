import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/database/app_database.dart';
import '../../data/daos/recurring_dao.dart';
import '../entities/recurring_entity.dart';

// ── Mapper ────────────────────────────────────────────────────────────────────

extension RecurringRowMapper on Recurring {
  RecurringEntity toEntity() => RecurringEntity(
        id: id,
        title: title,
        amount: amount,
        type: type,
        category: category,
        frequency: RecurringFrequency.values.firstWhere(
          (f) => f.name == frequency,
          orElse: () => RecurringFrequency.monthly,
        ),
        dayOfMonth: dayOfMonth,
        dayOfWeek: dayOfWeek,
        isActive: isActive,
        nextDue: nextDue,
        note: note,
      );
}

// ── Use Cases ─────────────────────────────────────────────────────────────────

class GetRecurringsUseCase {
  final RecurringDao _dao;
  GetRecurringsUseCase(this._dao);

  Stream<List<RecurringEntity>> watch() => _dao
      .watchAllRecurrings()
      .map((list) => list.map((r) => r.toEntity()).toList());

  Future<List<RecurringEntity>> getAll() async {
    final list = await _dao.getAllRecurrings();
    return list.map((r) => r.toEntity()).toList();
  }
}

class AddRecurringUseCase {
  final RecurringDao _dao;
  AddRecurringUseCase(this._dao);

  Future<void> call(RecurringEntity entity) => _dao.insertRecurring(
        RecurringsCompanion.insert(
          id: entity.id.isEmpty ? Uuid().v4() : entity.id,
          title: entity.title,
          amount: entity.amount,
          type: entity.type,
          category: entity.category,
          frequency: Value(entity.frequency.name),
          dayOfMonth: Value(entity.dayOfMonth),
          dayOfWeek: Value(entity.dayOfWeek),
          isActive: Value(entity.isActive),
          nextDue: entity.nextDue,
          note: Value(entity.note),
        ),
      );
}

class UpdateRecurringUseCase {
  final RecurringDao _dao;
  UpdateRecurringUseCase(this._dao);

  Future<void> call(RecurringEntity entity) => _dao.updateRecurring(
        entity.id,
        RecurringsCompanion(
          title: Value(entity.title),
          amount: Value(entity.amount),
          type: Value(entity.type),
          category: Value(entity.category),
          frequency: Value(entity.frequency.name),
          dayOfMonth: Value(entity.dayOfMonth),
          dayOfWeek: Value(entity.dayOfWeek),
          isActive: Value(entity.isActive),
          nextDue: Value(entity.nextDue),
          note: Value(entity.note),
        ),
      );
}

class DeleteRecurringUseCase {
  final RecurringDao _dao;
  DeleteRecurringUseCase(this._dao);

  Future<void> call(String id) => _dao.deleteRecurring(id);
}

class ToggleRecurringUseCase {
  final RecurringDao _dao;
  ToggleRecurringUseCase(this._dao);

  Future<void> call(String id, {required bool isActive}) =>
      _dao.toggleActive(id, isActive: isActive);
}

/// Hitung nextDue berikutnya berdasarkan frekuensi.
DateTime computeNextDue(RecurringFrequency frequency,
    {required int dayOfMonth, required int dayOfWeek}) {
  final now = DateTime.now();
  if (frequency == RecurringFrequency.monthly) {
    // Cari tanggal bulan ini, jika sudah lewat ambil bulan depan
    var candidate = DateTime(now.year, now.month, dayOfMonth);
    if (!candidate.isAfter(now)) {
      candidate = DateTime(now.year, now.month + 1, dayOfMonth);
    }
    return candidate;
  } else {
    // Weekly — cari hari dalam minggu ini/berikutnya
    var candidate = now;
    for (int i = 0; i <= 7; i++) {
      candidate = now.add(Duration(days: i));
      if (candidate.weekday == dayOfWeek && candidate.isAfter(now)) {
        break;
      }
    }
    return candidate;
  }
}