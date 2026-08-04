import 'dart:math';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;
  NotificationService._();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static const List<String> inactivityMessages = [
    'Dompet kamu kangen disentuh nih! 💸 Sudah catat pengeluaran hari ini?',
    'Jangan sampai dompet bocor halus! 🕳️ Catat pengeluaranmu sekarang.',
    'Ada transaksi misterius hari ini? 🔍 Yuk catat di Spendly sebelum lupa!',
    'Kopi siang ini berapaan? ☕ Jangan lupa dicatat ya!',
    'Struk belanjaan numpuk di kantong? 🧾 Pakai OCR Spendly buat scan cepat!',
    'Ingat impian finansialmu! 🎯 Tiap rupiah yang dicatat membawamu lebih dekat.',
    'Uang dingin atau uang panas? 🥶 Catat dulu biar nggak menguap gitu aja!',
    'Hei, sepertinya kamu belum mencatat pengeluaran hari ini. 📝',
    'Sudah jam segini, yuk luangkan 10 detik buat update saldo Spendly! ⏳',
    'Pengeluaran hari ini aman atau bablas? 🛑 Cek dan catat di Spendly!',
    'Gaji numpang lewat? 🏃‍♂️ Kendalikan dengan rajin mencatat transaksi.',
    'Keuangan rapi, hati pun tenang. 🧘‍♂️ Catat transaksi hari ini yuk!',
  ];

  Future<void> initialize() async {
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
          title: message.notification?.title ?? 'Spendly',
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
      channelDescription: 'Pengingat keuangan dan rekap mingguan Spendly',
      importance: Importance.high,
      priority: Priority.high,
    );
    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );

    await _localNotifications.show(id, title, body, notificationDetails);
  }

  static String getRandomInactivityMessage() {
    final rand = Random();
    return inactivityMessages[rand.nextInt(inactivityMessages.length)];
  }

  static String formatWeeklyRecapMessage(double totalSpent, String topCategory) {
    if (totalSpent <= 0) {
      return 'Minggu ini kamu hebat! Belum ada pengeluaran besar yang tercatat. 🎉';
    }
    final formatted = totalSpent.toStringAsFixed(0);
    return 'Total pengeluaran minggu ini: Rp $formatted. Kategori terbanyak: $topCategory 📊';
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
        title: 'Pengingat Keuangan Spendly 💡',
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
  debugPrint('[FCM] Background: ${message.notification?.title}');
}