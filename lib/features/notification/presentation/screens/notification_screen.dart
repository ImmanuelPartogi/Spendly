import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Notification Screen
// ─────────────────────────────────────────────────────────────────────────────
//
// STATUS: UI tersedia, sistem backend BELUM aktif.
//
// TODO [FUTURE UPDATE — Notification Backend]:
// Sistem notifikasi akan diimplementasikan penuh di versi berikutnya.
// Rencana implementasi:
//   1. flutter_local_notifications → notifikasi lokal (budget warning, due date)
//   2. Firebase Cloud Messaging → push notification dari server
//   3. Drift table 'Notifications' → simpan riwayat notifikasi lokal
//   4. Riverpod provider → notificationListProvider (StreamProvider)
//   5. Integrasi dengan InsightEngine → auto-generate notifikasi budget
//
// Data yang ditampilkan saat ini adalah DEMO PLACEHOLDER.
// Ganti dengan ref.watch(notificationListProvider) setelah backend siap.
// ─────────────────────────────────────────────────────────────────────────────

/// Model data notifikasi — sudah final dan siap dipakai.
/// Pindahkan ke file terpisah saat backend diimplementasi.
enum NotificationType {
  budgetWarning,
  budgetExceeded,
  goalAchieved,
  monthlyReport,
  recurringReminder,
  tip;

  String get defaultTitle {
    switch (this) {
      case NotificationType.budgetWarning:    return 'Budget Hampir Habis';
      case NotificationType.budgetExceeded:   return 'Budget Terlampaui';
      case NotificationType.goalAchieved:     return 'Goal Tercapai! 🎉';
      case NotificationType.monthlyReport:    return 'Laporan Bulanan';
      case NotificationType.recurringReminder:return 'Reminder Transaksi';
      case NotificationType.tip:              return 'Tips Keuangan';
    }
  }

  static NotificationType fromString(String value) =>
      NotificationType.values.firstWhere(
        (e) => e.name == value,
        orElse: () => NotificationType.tip,
      );
}

class NotificationModel {
  final String id;
  final NotificationType type;
  final String title;
  final String body;
  final DateTime createdAt;
  final bool isRead;
  final String? routeTarget;
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

  IconData get icon {
    switch (type) {
      case NotificationType.budgetWarning:    return Icons.warning_amber_rounded;
      case NotificationType.budgetExceeded:   return Icons.error_rounded;
      case NotificationType.goalAchieved:     return Icons.emoji_events_rounded;
      case NotificationType.monthlyReport:    return Icons.bar_chart_rounded;
      case NotificationType.recurringReminder:return Icons.repeat_rounded;
      case NotificationType.tip:              return Icons.lightbulb_rounded;
    }
  }

  Color get color {
    switch (type) {
      case NotificationType.budgetWarning:    return AppColors.warning;
      case NotificationType.budgetExceeded:   return AppColors.expense;
      case NotificationType.goalAchieved:     return AppColors.income;
      case NotificationType.monthlyReport:    return AppColors.primary;
      case NotificationType.recurringReminder:return AppColors.accentPurple;
      case NotificationType.tip:              return AppColors.accentTeal;
    }
  }

  NotificationModel copyWith({bool? isRead}) => NotificationModel(
        id:          id,
        type:        type,
        title:       title,
        body:        body,
        createdAt:   createdAt,
        isRead:      isRead ?? this.isRead,
        routeTarget: routeTarget,
        payload:     payload,
      );
}

// ─────────────────────────────────────────────────────────────────────────────

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  // ── DEMO DATA — ganti dengan ref.watch(notificationListProvider) ───────────
  // TODO [FUTURE UPDATE]: Hapus data demo ini dan sambungkan ke provider:
  //
  // final notificationsAsync = ref.watch(notificationListProvider);
  //
  // Provider akan watch Drift table + FCM stream secara realtime.
  late final List<NotificationModel> _notifications = [
    NotificationModel(
      id: '1',
      type: NotificationType.budgetWarning,
      title: 'Budget Food hampir habis',
      body: 'Kamu sudah memakai 87% budget Food bulan ini. Sisa Rp 117.000.',
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      isRead: false,
    ),
    NotificationModel(
      id: '2',
      type: NotificationType.monthlyReport,
      title: 'Laporan Februari tersedia',
      body: 'Ringkasan keuangan Februari sudah bisa dilihat di Analytics.',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      isRead: false,
    ),
    NotificationModel(
      id: '3',
      type: NotificationType.recurringReminder,
      title: 'Reminder: Cicilan Kredit',
      body: 'Cicilan kartu kredit jatuh tempo besok (tgl 15).',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      isRead: true,
    ),
    NotificationModel(
      id: '4',
      type: NotificationType.goalAchieved,
      title: '🎉 Goal tercapai!',
      body: 'Selamat! Kamu sudah mencapai target tabungan "Dana Darurat".',
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
      isRead: true,
    ),
    NotificationModel(
      id: '5',
      type: NotificationType.tip,
      title: '💡 Tips Hemat',
      body:
          'Pengeluaran transport kamu naik 30% bulan ini. Coba cek alternatif transportasinya.',
      createdAt: DateTime.now().subtract(const Duration(days: 5)),
      isRead: true,
    ),
  ];
  // ── END DEMO DATA ──────────────────────────────────────────────────────────

  int get _unreadCount =>
      _notifications.where((n) => !n.isRead).length;

  void _markRead(String id) {
    setState(() {
      final i = _notifications.indexWhere((n) => n.id == id);
      if (i >= 0) {
        _notifications[i] = _notifications[i].copyWith(isRead: true);
      }
    });
  }

  void _markAllRead() {
    setState(() {
      for (var i = 0; i < _notifications.length; i++) {
        _notifications[i] = _notifications[i].copyWith(isRead: true);
      }
    });
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m lalu';
    if (diff.inHours  < 24) return '${diff.inHours}j lalu';
    return '${diff.inDays}h lalu';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Notifikasi'),
        actions: [
          if (_unreadCount > 0)
            TextButton(
              onPressed: _markAllRead,
              child: const Text('Tandai Dibaca'),
            ),
        ],
      ),
      body: _notifications.isEmpty
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('🔔', style: TextStyle(fontSize: 48)),
                  SizedBox(height: 12),
                  Text('Tidak ada notifikasi',
                      style: TextStyle(
                          fontSize: 16,
                          color: AppColors.textSecondary,),),
                ],
              ),
            )
          : ListView.separated(
              itemCount: _notifications.length,
              separatorBuilder: (_, __) =>
                  const Divider(height: 1, indent: 72),
              itemBuilder: (_, i) {
                final n = _notifications[i];
                return _NotificationTile(
                  notification: n,
                  timeAgo: _timeAgo(n.createdAt),
                  onTap: () {
                    _markRead(n.id);
                    // TODO [FUTURE UPDATE]: Navigate to n.routeTarget
                    // if (n.routeTarget != null) {
                    //   context.push(n.routeTarget!);
                    // }
                  },
                );
              },
            ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _NotificationTile extends StatelessWidget {
  final NotificationModel notification;
  final String timeAgo;
  final VoidCallback onTap;

  const _NotificationTile({
    required this.notification,
    required this.timeAgo,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final n = notification;
    return InkWell(
      onTap: onTap,
      child: Container(
        color: n.isRead ? null : n.color.withValues(alpha: 0.04),
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: n.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(n.icon, color: n.color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          n.title,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: n.isRead
                                ? FontWeight.w500
                                : FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(timeAgo,
                          style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textHint,),),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(n.body,
                      style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          height: 1.4,),),
                ],
              ),
            ),
            if (!n.isRead)
              Padding(
                padding: const EdgeInsets.only(left: 8, top: 2),
                child: Container(
                  width: 8, height: 8,
                  decoration: BoxDecoration(
                      color: n.color, shape: BoxShape.circle,),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Notification Badge Widget (untuk AppBar) ──────────────────────────────────
//
// TODO [FUTURE UPDATE]: count akan dari ref.watch(unreadNotificationCountProvider)

class NotificationBadge extends StatelessWidget {
  final int count;
  final VoidCallback onTap;

  const NotificationBadge({
    super.key,
    required this.count,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        IconButton(
          icon: const Icon(Icons.notifications_none_rounded),
          color: AppColors.textSecondary,
          onPressed: onTap,
        ),
        if (count > 0)
          Positioned(
            right: 8, top: 8,
            child: Container(
              width: 16, height: 16,
              decoration: const BoxDecoration(
                  color: AppColors.expense, shape: BoxShape.circle,),
              child: Center(
                child: Text(
                  count > 9 ? '9+' : count.toString(),
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,),
                ),
              ),
            ),
          ),
      ],
    );
  }
}