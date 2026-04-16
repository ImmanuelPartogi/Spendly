import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/database/app_database.dart';
import '../../domain/entities/transaction_entity.dart';

class TransactionModel {
  // ── Drift → Entity ────────────────────────────────────────────────────────
  static TransactionEntity fromDrift(Transaction tx) =>
      TransactionEntity(
        id: tx.id,
        walletId: tx.walletId,
        amount: tx.amount,
        type: tx.type,
        category: tx.category,
        note: tx.note,
        date: tx.date,
        createdAt: tx.createdAt,
      );

  // ── Entity → Drift Companion ──────────────────────────────────────────────
  static TransactionsCompanion toCompanion(TransactionEntity e) =>
      TransactionsCompanion.insert(
        id: e.id,
        walletId: e.walletId,
        amount: e.amount,
        type: e.type,
        category: e.category,
        note: Value(e.note),
        date: e.date,
        createdAt: Value(e.createdAt),
        synced: const Value(false),
        isLocked: const Value(false),
      );

  // ── Entity → JSON (untuk Firebase) ───────────────────────────────────────
  static Map<String, dynamic> toJson(TransactionEntity e) => {
        'id': e.id,
        'walletId': e.walletId,
        'amount': e.amount,
        'type': e.type,
        'category': e.category,
        'note': e.note,
        'date': e.date.toIso8601String(),
        'createdAt': e.createdAt.toIso8601String(),
        'deleted': false,
      };

  // ── JSON (dari Firebase) → Entity ─────────────────────────────────────────
  static TransactionEntity fromJson(Map<String, dynamic> json) =>
      TransactionEntity(
        id: json['id'] as String,
        walletId: json['walletId'] as String,
        amount: (json['amount'] as num).toDouble(),
        type: json['type'] as String,
        category: json['category'] as String,
        note: json['note'] as String?,
        date: _parseDate(json['date']),
        createdAt: _parseDate(json['createdAt']),
      );

  // ── Factory: buat transaksi baru ──────────────────────────────────────────
  static TransactionEntity create({
    required String walletId,
    required double amount,
    required String type,
    required String category,
    String? note,
    DateTime? date,
  }) =>
      TransactionEntity(
        id: const Uuid().v4(),
        walletId: walletId,
        amount: amount,
        type: type,
        category: category,
        note: note,
        date: date ?? DateTime.now(),
        createdAt: DateTime.now(),
      );

  // ── Helper ────────────────────────────────────────────────────────────────
  static DateTime _parseDate(dynamic value) {
    if (value is String) return DateTime.parse(value);
    // Firestore Timestamp
    if (value != null && value.runtimeType.toString() == 'Timestamp') {
      return (value as dynamic).toDate() as DateTime;
    }
    return DateTime.now();
  }
}