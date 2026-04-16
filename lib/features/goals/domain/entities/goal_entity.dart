import 'package:flutter/material.dart';

/// Entity yang merepresentasikan satu Financial Goal.
class GoalEntity {
  final String id;
  final String title;
  final String emoji;
  final double targetAmount;
  final double currentAmount;
  final DateTime deadline;
  final Color color;
  final bool isCompleted;
  final DateTime createdAt;

  const GoalEntity({
    required this.id,
    required this.title,
    required this.emoji,
    required this.targetAmount,
    required this.currentAmount,
    required this.deadline,
    required this.color,
    this.isCompleted = false,
    required this.createdAt,
  });

  // ─── Computed ─────────────────────────────────────────────────────────────

  /// Persentase progres (0.0 – 1.0).
  double get progress =>
      (currentAmount / targetAmount).clamp(0.0, 1.0);

  /// Sisa nominal yang harus dikumpulkan.
  double get remaining =>
      (targetAmount - currentAmount).clamp(0.0, double.infinity);

  /// Sisa hari menuju deadline (0 jika sudah lewat).
  int get daysLeft =>
      deadline.difference(DateTime.now()).inDays.clamp(0, 9999);

  /// Nominal harian yang perlu dialokasikan agar tepat waktu.
  double get dailySavingsNeeded =>
      daysLeft > 0 ? remaining / daysLeft : 0;

  /// Apakah deadline sudah terlewati tanpa tercapai.
  bool get isOverdue =>
      !isCompleted && DateTime.now().isAfter(deadline);

  // ─── copyWith ─────────────────────────────────────────────────────────────

  GoalEntity copyWith({
    String?   id,
    String?   title,
    String?   emoji,
    double?   targetAmount,
    double?   currentAmount,
    DateTime? deadline,
    Color?    color,
    bool?     isCompleted,
    DateTime? createdAt,
  }) {
    return GoalEntity(
      id:            id            ?? this.id,
      title:         title         ?? this.title,
      emoji:         emoji         ?? this.emoji,
      targetAmount:  targetAmount  ?? this.targetAmount,
      currentAmount: currentAmount ?? this.currentAmount,
      deadline:      deadline      ?? this.deadline,
      color:         color         ?? this.color,
      isCompleted:   isCompleted   ?? this.isCompleted,
      createdAt:     createdAt     ?? this.createdAt,
    );
  }

  // ─── Serialization ────────────────────────────────────────────────────────

  Map<String, dynamic> toJson() => {
        'id':            id,
        'title':         title,
        'emoji':         emoji,
        'targetAmount':  targetAmount,
        'currentAmount': currentAmount,
        'deadline':      deadline.toIso8601String(),
        'color':         color.value,
        'isCompleted':   isCompleted,
        'createdAt':     createdAt.toIso8601String(),
      };

  factory GoalEntity.fromJson(Map<String, dynamic> json) => GoalEntity(
        id:            json['id'] as String,
        title:         json['title'] as String,
        emoji:         json['emoji'] as String,
        targetAmount:  (json['targetAmount'] as num).toDouble(),
        currentAmount: (json['currentAmount'] as num).toDouble(),
        deadline:      DateTime.parse(json['deadline'] as String),
        color:         Color(json['color'] as int),
        isCompleted:   json['isCompleted'] as bool? ?? false,
        createdAt:     DateTime.parse(json['createdAt'] as String),
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GoalEntity &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'GoalEntity(id: $id, title: $title, '
      'progress: ${(progress * 100).toStringAsFixed(0)}%)';
}