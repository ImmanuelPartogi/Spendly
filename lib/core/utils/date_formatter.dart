import 'package:intl/intl.dart';

class DateFormatter {
  DateFormatter._();

  static final DateFormat _dayMonthYear = DateFormat('dd MMM yyyy');
  static final DateFormat _dayMonth = DateFormat('dd MMM');
  static final DateFormat _monthYear = DateFormat('MMMM yyyy');

  static String formatDate(DateTime date) => _dayMonthYear.format(date);
  static String formatDayMonth(DateTime date) => _dayMonth.format(date);
  static String formatMonthYear(DateTime date) => _monthYear.format(date);

  static String formatRelative(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateOnly = DateTime(date.year, date.month, date.day);
    if (dateOnly == today) return 'Today';
    if (dateOnly == yesterday) return 'Yesterday';
    return _dayMonthYear.format(date);
  }

  static DateTime startOfMonth(DateTime date) => DateTime(date.year, date.month, 1);
  static DateTime endOfMonth(DateTime date) => DateTime(date.year, date.month + 1, 0, 23, 59, 59);
}