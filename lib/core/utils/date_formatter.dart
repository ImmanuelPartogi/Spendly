import 'package:easy_localization/easy_localization.dart';
import 'package:intl/intl.dart';

// ─────────────────────────────────────────────────────────────────────────────
// DateFormatter — Lokalisasi dinamis berbasis locale aktif
// ─────────────────────────────────────────────────────────────────────────────

class DateFormatter {
  DateFormatter._();

  static DateFormat _getFormatter(String pattern, [String? locale]) {
    final activeLocale = locale ?? Intl.defaultLocale ?? 'id';
    return DateFormat(pattern, activeLocale);
  }

  /// Contoh: 17 Mei 2026
  static String formatDate(DateTime date, {String? locale}) =>
      _getFormatter('dd MMM yyyy', locale).format(date);

  /// Contoh: 17 Mei
  static String formatDayMonth(DateTime date, {String? locale}) =>
      _getFormatter('dd MMM', locale).format(date);

  /// Contoh: Mei 2026
  static String formatMonthYear(DateTime date, {String? locale}) =>
      _getFormatter('MMMM yyyy', locale).format(date);

  /// Contoh: Mei 26 / May 26
  static String formatMonthShort(DateTime date, {String? locale}) =>
      _getFormatter('MMM yy', locale).format(date);

  /// Contoh: Senin / Monday
  static String formatWeekday(DateTime date, {String? locale}) =>
      _getFormatter('EEEE', locale).format(date);

  /// Mengkonversi indeks hari (1 = Senin, 7 = Minggu) ke nama hari terlokalisasi
  static String formatWeekdayName(int weekday, {String? locale}) {
    final refDate = DateTime(2026, 5, 4 + (weekday - 1));
    return _getFormatter('EEEE', locale).format(refDate);
  }

  /// Mengembalikan 'Hari ini', 'Kemarin', atau tanggal lengkap terlokalisasi
  static String formatRelative(DateTime date, {String? locale}) {
    final now       = DateTime.now();
    final today     = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateOnly  = DateTime(date.year, date.month, date.day);

    if (dateOnly == today)     return 'date_today'.tr();
    if (dateOnly == yesterday) return 'date_yesterday'.tr();
    return formatDate(date, locale: locale);
  }

  /// Awal bulan: 1 Mei 2026 00:00:00
  static DateTime startOfMonth(DateTime date) =>
      DateTime(date.year, date.month, 1);

  /// Akhir bulan: 31 Mei 2026 23:59:59
  static DateTime endOfMonth(DateTime date) =>
      DateTime(date.year, date.month + 1, 0, 23, 59, 59);
}