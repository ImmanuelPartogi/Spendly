import 'package:flutter/material.dart';

/// Enum untuk frekuensi transaksi berulang
enum RecurringFrequency {
  weekly('Mingguan'),
  monthly('Bulanan');

  const RecurringFrequency(this.label);
  final String label;
}

/// Entity yang merepresentasikan satu transaksi berulang.
class RecurringEntity {
  final String id;
  final String title;
  final double amount;
  final String type; // 'income' atau 'expense'
  final String category;
  final RecurringFrequency frequency;
  final int dayOfMonth; // 1-28 untuk bulanan, 0 untuk mingguan
  final int dayOfWeek;  // 0-6 untuk mingguan, 0 untuk bulanan
  final bool isActive;
  final DateTime nextDue;
  final String? note;

  const RecurringEntity({
    required this.id,
    required this.title,
    required this.amount,
    required this.type,
    required this.category,
    required this.frequency,
    required this.dayOfMonth,
    required this.dayOfWeek,
    required this.isActive,
    required this.nextDue,
    this.note,
  });

  // ─── Computed ─────────────────────────────────────────────────────────────

  /// Apakah ini transaksi pengeluaran
  bool get isExpense => type == 'expense';

  /// Apakah ini transaksi pemasukan
  bool get isIncome => type == 'income';

  // ─── copyWith ─────────────────────────────────────────────────────────────

  RecurringEntity copyWith({
    String? id,
    String? title,
    double? amount,
    String? type,
    String? category,
    RecurringFrequency? frequency,
    int? dayOfMonth,
    int? dayOfWeek,
    bool? isActive,
    DateTime? nextDue,
    String? note,
  }) {
    return RecurringEntity(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      category: category ?? this.category,
      frequency: frequency ?? this.frequency,
      dayOfMonth: dayOfMonth ?? this.dayOfMonth,
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      isActive: isActive ?? this.isActive,
      nextDue: nextDue ?? this.nextDue,
      note: note ?? this.note,
    );
  }

  // ─── Serialization ────────────────────────────────────────────────────────

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'amount': amount,
        'type': type,
        'category': category,
        'frequency': frequency.name,
        'dayOfMonth': dayOfMonth,
        'dayOfWeek': dayOfWeek,
        'isActive': isActive,
        'nextDue': nextDue.toIso8601String(),
        'note': note,
      };

  factory RecurringEntity.fromJson(Map<String, dynamic> json) => RecurringEntity(
        id: json['id'] as String,
        title: json['title'] as String,
        amount: (json['amount'] as num).toDouble(),
        type: json['type'] as String,
        category: json['category'] as String,
        frequency: RecurringFrequency.values.firstWhere(
          (f) => f.name == json['frequency'],
          orElse: () => RecurringFrequency.monthly,
        ),
        dayOfMonth: json['dayOfMonth'] as int,
        dayOfWeek: json['dayOfWeek'] as int,
        isActive: json['isActive'] as bool,
        nextDue: DateTime.parse(json['nextDue'] as String),
        note: json['note'] as String?,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RecurringEntity &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'RecurringEntity(id: $id, title: $title, amount: $amount, type: $type)';
}
