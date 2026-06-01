import 'package:intl/intl.dart';

// ─────────────────────────────────────────────────────────────────────────────
// DateFormatter
//
// Pastikan sudah memanggil initializeDateFormatting('id', null)
// di main.dart sebelum runApp agar nama bulan muncul dalam Bahasa Indonesia.
//
// FIX: DateFormat tidak lagi dibuat sebagai static final field (eager/lazy init
// yang bisa terpanggil sebelum initializeDateFormatting). Sekarang dibuat
// sebagai static getter → instance baru dibuat setiap kali dipanggil,
// dijamin locale sudah ter-init terlebih dahulu oleh main.dart.
// ─────────────────────────────────────────────────────────────────────────────

class DateFormatter {
  DateFormatter._();

  // Gunakan getter, bukan static final field, agar DateFormat baru dibuat
  // setelah initializeDateFormatting('id') dipanggil di main.dart.
  static DateFormat get _dayMonthYear => DateFormat('dd MMM yyyy', 'id');
  static DateFormat get _dayMonth     => DateFormat('dd MMM', 'id');
  static DateFormat get _monthYear    => DateFormat('MMMM yyyy', 'id');

  /// Contoh: 17 Mei 2026
  static String formatDate(DateTime date) => _dayMonthYear.format(date);

  /// Contoh: 17 Mei
  static String formatDayMonth(DateTime date) => _dayMonth.format(date);

  /// Contoh: Mei 2026
  static String formatMonthYear(DateTime date) => _monthYear.format(date);

  /// Mengembalikan 'Hari ini', 'Kemarin', atau tanggal lengkap
  static String formatRelative(DateTime date) {
    final now       = DateTime.now();
    final today     = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateOnly  = DateTime(date.year, date.month, date.day);

    if (dateOnly == today)     return 'Hari ini';
    if (dateOnly == yesterday) return 'Kemarin';
    return _dayMonthYear.format(date);
  }

  /// Awal bulan: 1 Mei 2026 00:00:00
  static DateTime startOfMonth(DateTime date) =>
      DateTime(date.year, date.month, 1);

  /// Akhir bulan: 31 Mei 2026 23:59:59
  static DateTime endOfMonth(DateTime date) =>
      DateTime(date.year, date.month + 1, 0, 23, 59, 59);
}