/// Format angka ringkas bergaya Indonesian.
/// Contoh: 1.500.000 → "1.5 jt", 250.000 → "250 rb"
class NumberFormatter {
  NumberFormatter._();

  /// Format ringkas: "1.2 jt", "250 rb", "1.1 M"
  static String formatShort(double amount) {
    if (amount >= 1_000_000_000) {
      return '${(amount / 1_000_000_000).toStringAsFixed(1)} M';
    } else if (amount >= 1_000_000) {
      return '${(amount / 1_000_000).toStringAsFixed(1)} jt';
    } else if (amount >= 1_000) {
      return '${(amount / 1_000).toStringAsFixed(0)} rb';
    }
    return amount.toStringAsFixed(0);
  }

  /// Format persen: 0.75 → "75%", 0.756 dengan decimals:1 → "75.6%"
  static String formatPercent(double value, {int decimals = 0}) {
    return '${(value * 100).toStringAsFixed(decimals)}%';
  }

  /// Delta perubahan antara dua nilai: "+12%", "-5%"
  static String formatDelta(double current, double previous) {
    if (previous == 0) return '+0%';
    final delta = ((current - previous) / previous) * 100;
    final sign = delta >= 0 ? '+' : '';
    return '$sign${delta.toStringAsFixed(0)}%';
  }

  /// Warna delta: positif → hijau, negatif → merah
  /// (Kembalikan true jika positif agar caller bisa pakai AppColors.income/expense)
  static bool isPositiveDelta(double current, double previous) {
    if (previous == 0) return true;
    return current >= previous;
  }
}