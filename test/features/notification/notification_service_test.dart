import 'package:flutter_test/flutter_test.dart';
import 'package:spendly/core/services/notification_service.dart';

void main() {
  group('NotificationService Unit Tests', () {
    test('inactivityMessages pool contains at least 10 messages', () {
      expect(NotificationService.inactivityMessages.length, greaterThanOrEqualTo(10));
    });

    test('getRandomInactivityMessage returns non-empty string from pool', () {
      final msg = NotificationService.getRandomInactivityMessage();
      expect(msg, isNotEmpty);
      expect(NotificationService.inactivityMessages, contains(msg));
    });

    test('formatWeeklyRecapMessage formats zero expense correctly', () {
      final msg = NotificationService.formatWeeklyRecapMessage(0, 'Belanja');
      expect(msg.toLowerCase(), contains('belum ada pengeluaran besar'));
    });

    test('formatWeeklyRecapMessage formats positive expense correctly', () {
      final msg = NotificationService.formatWeeklyRecapMessage(150000, 'Makanan & Minuman');
      expect(msg, contains('150000'));
      expect(msg, contains('Makanan & Minuman'));
    });
  });
}
