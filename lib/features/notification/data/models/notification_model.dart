import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// Tipe-tipe notifikasi yang dihasilkan Spendly.
enum NotificationType {
  budgetWarning,
  budgetExceeded,
  goalAchieved,
  monthlyReport,
  recurringReminder,
  tip;

  /// Judul default berdasarkan tipe.
  String get defaultTitle {
    switch (this) {
      case NotificationType.budgetWarning:
        return 'Budget Hampir Habis';
      case NotificationType.budgetExceeded:
        return 'Budget Terlampaui';
      case NotificationType.goalAchieved:
        return 'Goal Tercapai! 🎉';
      case NotificationType.monthlyReport:
        return 'Laporan Bulanan';
      case NotificationType.recurringReminder:
        return 'Reminder Transaksi';
      case NotificationType.tip:
        return 'Tips Keuangan';
    }
  }

  static NotificationType fromString(String value) =>
      NotificationType.values.firstWhere(
        (e) => e.name == value,
        orElse: () => NotificationType.tip,
      );
}

/// Model data untuk satu entri notifikasi.
class NotificationModel {
  final String id;
  final NotificationType type;
  final String title;
  final String body;
  final DateTime createdAt;
  final bool isRead;

  /// Route/deep link yang dibuka saat notifikasi di-tap.
  /// Contoh: '/budget', '/analytics', '/transactions'
  final String? routeTarget;

  /// Payload JSON tambahan (mis. ID budget atau goal yang terkait).
  final Map<String, dynamic>? payload;

  const NotificationModel({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.createdAt,
    this.isRead = false,
    this.routeTarget,
    this.payload,
  });

  // ─── Computed UI properties ────────────────────────────────────────────────

  IconData get icon {
    switch (type) {
      case NotificationType.budgetWarning:
        return Icons.warning_amber_rounded;
      case NotificationType.budgetExceeded:
        return Icons.error_rounded;
      case NotificationType.goalAchieved:
        return Icons.emoji_events_rounded;
      case NotificationType.monthlyReport:
        return Icons.bar_chart_rounded;
      case NotificationType.recurringReminder:
        return Icons.repeat_rounded;
      case NotificationType.tip:
        return Icons.lightbulb_rounded;
    }
  }

  Color get color {
    switch (type) {
      case NotificationType.budgetWarning:
        return AppColors.warning;
      case NotificationType.budgetExceeded:
        return AppColors.expense;
      case NotificationType.goalAchieved:
        return AppColors.income;
      case NotificationType.monthlyReport:
        return AppColors.primary;
      case NotificationType.recurringReminder:
        return AppColors.accentPurple;
      case NotificationType.tip:
        return AppColors.accentTeal;
    }
  }

  // ─── copyWith ──────────────────────────────────────────────────────────────

  NotificationModel copyWith({
    String?                  id,
    NotificationType?        type,
    String?                  title,
    String?                  body,
    DateTime?                createdAt,
    bool?                    isRead,
    String?                  routeTarget,
    Map<String, dynamic>?    payload,
  }) {
    return NotificationModel(
      id:          id          ?? this.id,
      type:        type        ?? this.type,
      title:       title       ?? this.title,
      body:        body        ?? this.body,
      createdAt:   createdAt   ?? this.createdAt,
      isRead:      isRead      ?? this.isRead,
      routeTarget: routeTarget ?? this.routeTarget,
      payload:     payload     ?? this.payload,
    );
  }

  // ─── Serialization ─────────────────────────────────────────────────────────

  Map<String, dynamic> toJson() => {
        'id':          id,
        'type':        type.name,
        'title':       title,
        'body':        body,
        'createdAt':   createdAt.toIso8601String(),
        'isRead':      isRead,
        'routeTarget': routeTarget,
        'payload':     payload,
      };

  factory NotificationModel.fromJson(Map<String, dynamic> json) =>
      NotificationModel(
        id:          json['id'] as String,
        type:        NotificationType.fromString(json['type'] as String),
        title:       json['title'] as String,
        body:        json['body'] as String,
        createdAt:   DateTime.parse(json['createdAt'] as String),
        isRead:      json['isRead'] as bool? ?? false,
        routeTarget: json['routeTarget'] as String?,
        payload: json['payload'] != null
            ? Map<String, dynamic>.from(
                json['payload'] as Map)
            : null,
      );

  // ─── Factory helpers ────────────────────────────────────────────────────────

  /// Buat notifikasi peringatan budget hampir habis.
  factory NotificationModel.budgetWarning({
    required String id,
    required String category,
    required int percentUsed,
    required String remaining,
  }) =>
      NotificationModel(
        id:          id,
        type:        NotificationType.budgetWarning,
        title:       'Budget $category hampir habis',
        body:        'Kamu sudah memakai $percentUsed% budget '
                     '$category. Sisa $remaining.',
        createdAt:   DateTime.now(),
        routeTarget: '/budget',
        payload:     {'category': category},
      );

  /// Buat notifikasi laporan bulanan.
  factory NotificationModel.monthlyReport({
    required String id,
    required String monthLabel,
  }) =>
      NotificationModel(
        id:          id,
        type:        NotificationType.monthlyReport,
        title:       'Laporan $monthLabel Tersedia',
        body:        'Ringkasan keuangan $monthLabel sudah bisa '
                     'dilihat di Analytics.',
        createdAt:   DateTime.now(),
        routeTarget: '/analytics',
      );

  /// Buat notifikasi reminder transaksi berulang.
  factory NotificationModel.recurringReminder({
    required String id,
    required String title,
    required String dueLabel,
  }) =>
      NotificationModel(
        id:          id,
        type:        NotificationType.recurringReminder,
        title:       'Reminder: $title',
        body:        'Transaksi berulang "$title" jatuh tempo $dueLabel.',
        createdAt:   DateTime.now(),
        routeTarget: '/recurring',
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NotificationModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'NotificationModel(id: $id, type: ${type.name}, '
      'isRead: $isRead)';
}