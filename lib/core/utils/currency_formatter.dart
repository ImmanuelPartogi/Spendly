import 'package:intl/intl.dart';

// ─────────────────────────────────────────────────────────────────────────────
// CurrencyFormatter — Lokalisasi mata uang dinamis berbasis locale aktif
// ─────────────────────────────────────────────────────────────────────────────

class CurrencyFormatter {
  CurrencyFormatter._();

  static String _resolveSymbol(String langCode) {
    switch (langCode.toLowerCase()) {
      case 'id':
        return 'Rp ';
      case 'en':
        return '\$';
      case 'ms':
        return 'RM ';
      case 'es':
      case 'fr':
      case 'de':
      case 'pt':
        return '€';
      case 'zh':
      case 'ja':
        return '¥';
      case 'hi':
        return '₹';
      case 'ru':
        return '₽';
      case 'ko':
        return '₩';
      case 'vi':
        return '₫';
      default:
        return 'Rp ';
    }
  }

  static NumberFormat _getFormatter({String? locale, String? symbol, int decimalDigits = 0}) {
    final activeLocale = locale ?? Intl.defaultLocale ?? 'id';
    final langCode = activeLocale.split('_').first;
    final activeSymbol = symbol ?? _resolveSymbol(langCode);
    return NumberFormat.currency(
      locale: activeLocale,
      symbol: activeSymbol,
      decimalDigits: decimalDigits,
    );
  }

  static NumberFormat _getCompactFormatter({String? locale, String? symbol}) {
    final activeLocale = locale ?? Intl.defaultLocale ?? 'id';
    final langCode = activeLocale.split('_').first;
    final activeSymbol = symbol ?? _resolveSymbol(langCode);
    return NumberFormat.compactCurrency(
      locale: activeLocale,
      symbol: activeSymbol,
      decimalDigits: 1,
    );
  }

  static String format(double amount, {String? locale, String? symbol}) =>
      _getFormatter(locale: locale, symbol: symbol).format(amount);

  static String formatCompact(double amount, {String? locale, String? symbol}) {
    if (amount.abs() >= 1000000) {
      return _getCompactFormatter(locale: locale, symbol: symbol).format(amount);
    }
    return format(amount, locale: locale, symbol: symbol);
  }

  static String formatWithSign(double amount, {bool isExpense = false, String? locale, String? symbol}) {
    final prefix = isExpense ? '- ' : '+ ';
    return '$prefix${format(amount.abs(), locale: locale, symbol: symbol)}';
  }
}