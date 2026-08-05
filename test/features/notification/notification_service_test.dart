import 'package:flutter_test/flutter_test.dart';
import 'package:spendly/core/services/notification_service.dart';

void main() {
  group('NotificationService Unit Tests', () {
    test('getRandomInactivityMessage returns non-empty localized key', () {
      final msg = NotificationService.getRandomInactivityMessage();
      expect(msg, isNotEmpty);
      expect(msg, equals('inactivity_reminder'));
    });

    test('formatWeeklyRecapMessage formats zero expense correctly', () {
      final msg = NotificationService.formatWeeklyRecapMessage(0, 'cat_belanja');
      expect(msg, equals('notif_weekly_recap_body_zero'));
    });

    test('formatWeeklyRecapMessage formats positive expense correctly', () {
      final msg = NotificationService.formatWeeklyRecapMessage(150000, 'cat_makanan_minuman');
      expect(msg, equals('notif_weekly_recap_body_positive'));
    });
  });
}
