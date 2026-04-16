import 'package:intl/intl.dart';

class CurrencyFormatter {
  CurrencyFormatter._();

  static final NumberFormat _idrFormatter = NumberFormat.currency(
    locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0,
  );
  static final NumberFormat _compactFormatter = NumberFormat.compactCurrency(
    locale: 'id_ID', symbol: 'Rp ', decimalDigits: 1,
  );

  static String format(double amount) => _idrFormatter.format(amount);

  static String formatCompact(double amount) {
    if (amount.abs() >= 1000000) return _compactFormatter.format(amount);
    return format(amount);
  }

  static String formatWithSign(double amount, {bool isExpense = false}) {
    final prefix = isExpense ? '- ' : '+ ';
    return '$prefix${_idrFormatter.format(amount.abs())}';
  }
}