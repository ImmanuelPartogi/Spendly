import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../utils/currency_formatter.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;
  NotificationService._();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    tz.initializeTimeZones();

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(settings);

    try {
      final fcmSettings = await _fcm.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      if (fcmSettings.authorizationStatus == AuthorizationStatus.authorized) {
        debugPrint('[FCM] Permission granted');
      }
    } catch (e) {
      debugPrint('[FCM] Setup warning: $e');
    }

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('[FCM] Foreground: ${message.notification?.title}');
      if (message.notification != null) {
        showNotification(
          id: message.hashCode,
          title: message.notification?.title ?? 'appName'.tr(),
          body: message.notification?.body ?? '',
        );
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('[FCM] Opened from background: ${message.data}');
    });

    try {
      await _fcm.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
    } catch (_) {}
  }

  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'spendly_channel',
      'Spendly Notifications',
      channelDescription: 'Spendly notifications channel',
      importance: Importance.high,
      priority: Priority.high,
    );
    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );

    await _localNotifications.show(id, title, body, notificationDetails);
  }

  /// D1 — Peringatan Budget Instan (>=80% & >=100%)
  Future<void> checkAndSendBudgetNotification({
    required String category,
    required double spent,
    required double limit,
    required DateTime month,
  }) async {
    if (limit <= 0) return;

    int? threshold;
    if (spent >= limit) {
      threshold = 100;
    } else if (spent >= limit * 0.8) {
      threshold = 80;
    }

    if (threshold == null) return;

    final prefs = await SharedPreferences.getInstance();
    final prefKey =
        'notif_budget_${category}_${month.year}_${month.month}_$threshold';
    final alreadyNotified = prefs.getBool(prefKey) ?? false;
    if (alreadyNotified) return;

    await prefs.setBool(prefKey, true);

    final title = 'notif_budget_title'.tr();
    final formattedSpent = CurrencyFormatter.formatCompact(spent);
    final formattedLimit = CurrencyFormatter.formatCompact(limit);

    final body = threshold == 100
        ? 'notif_budget_exceeded'.tr(namedArgs: {'category': category, 'spent': formattedSpent, 'limit': formattedLimit})
        : 'notif_budget_warning_80'.tr(namedArgs: {'category': category, 'spent': formattedSpent, 'limit': formattedLimit});

    await showNotification(
      id: ('budget_${category}_$threshold').hashCode,
      title: title,
      body: body,
    );
  }

  /// D3 — Selebrasi Goal Achieved
  Future<void> sendGoalAchievedNotification({required String goalTitle}) async {
    await showNotification(
      id: ('goal_$goalTitle').hashCode,
      title: 'notif_goal_achieved_title'.tr(),
      body: 'notif_goal_achieved_body'.tr(namedArgs: {'goal': goalTitle}),
    );
  }

  /// D2 — Reminder Transaksi Berulang Jatuh Tempo (H-1 & Hari H)
  Future<void> scheduleRecurringNotification({
    required String recurringId,
    required String title,
    required double amount,
    required DateTime nextDue,
  }) async {
    final baseId = recurringId.hashCode;
    await _localNotifications.cancel(baseId);
    await _localNotifications.cancel(baseId + 1);

    final now = DateTime.now();
    final formattedAmount = CurrencyFormatter.formatCompact(amount);

    const androidDetails = AndroidNotificationDetails(
      'spendly_recurring_channel',
      'Spendly Recurring Reminder',
      channelDescription: 'Spendly recurring notification channel',
      importance: Importance.high,
      priority: Priority.high,
    );
    const details = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );

    // 1. H-1 Reminder
    final hMinus1 = DateTime(nextDue.year, nextDue.month, nextDue.day - 1, 9, 0);
    if (hMinus1.isAfter(now)) {
      try {
        await _localNotifications.zonedSchedule(
          baseId,
          'notif_recurring_title'.tr(),
          'notif_recurring_body'.tr(namedArgs: {'title': title, 'amount': formattedAmount}),
          tz.TZDateTime.from(hMinus1, tz.local),
          details,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
        );
      } catch (e) {
        debugPrint('[NotificationService] Schedule H-1 warning: $e');
      }
    }

    // 2. Day-H Reminder
    final dayH = DateTime(nextDue.year, nextDue.month, nextDue.day, 9, 0);
    if (dayH.isAfter(now)) {
      try {
        await _localNotifications.zonedSchedule(
          baseId + 1,
          'notif_recurring_title'.tr(),
          'notif_recurring_body'.tr(namedArgs: {'title': title, 'amount': formattedAmount}),
          tz.TZDateTime.from(dayH, tz.local),
          details,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
        );
      } catch (e) {
        debugPrint('[NotificationService] Schedule Day-H warning: $e');
      }
    }
  }

  static String getRandomInactivityMessage() {
    return 'inactivity_reminder'.tr();
  }

  static String formatWeeklyRecapMessage(double totalSpent, String topCategory) {
    if (totalSpent <= 0) {
      return 'notif_weekly_recap_body_zero'.tr();
    }
    final formatted = totalSpent.toStringAsFixed(0);
    return 'notif_weekly_recap_body_positive'.tr(namedArgs: {'spent': formatted, 'category': topCategory});
  }

  /// Mengecek apakah transaksi hari ini sudah ada. Jika belum, picu pengingat.
  Future<bool> checkAndTriggerInactivityReminder({
    required DateTime? lastTransactionDate,
  }) async {
    final now = DateTime.now();
    final hasTransactionToday = lastTransactionDate != null &&
        lastTransactionDate.year == now.year &&
        lastTransactionDate.month == now.month &&
        lastTransactionDate.day == now.day;

    if (!hasTransactionToday) {
      await showNotification(
        id: 1001,
        title: 'notif_weekly_recap_title'.tr(),
        body: getRandomInactivityMessage(),
      );
      return true;
    }
    return false;
  }

  Future<String?> getToken() async {
    try {
      return await _fcm.getToken();
    } catch (_) {
      return null;
    }
  }
}

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await EasyLocalization.ensureInitialized();
  } catch (_) {}
  debugPrint('[FCM] Background: ${message.notification?.title}');
}