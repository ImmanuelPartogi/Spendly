import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _kNotificationEnabledKey = 'notification_enabled_pref';

final notificationEnabledProvider =
    StateNotifierProvider<NotificationPrefNotifier, bool>((ref) {
  return NotificationPrefNotifier();
});

class NotificationPrefNotifier extends StateNotifier<bool> {
  NotificationPrefNotifier() : super(true) {
    _loadPref();
  }

  Future<void> _loadPref() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool(_kNotificationEnabledKey) ?? true;
  }

  Future<void> toggleNotification(bool enabled) async {
    state = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kNotificationEnabledKey, enabled);
  }
}
