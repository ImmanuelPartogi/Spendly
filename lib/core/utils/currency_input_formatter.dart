import 'package:flutter/services.dart';

/// Input formatter yang otomatis menambahkan titik (.) sebagai
/// thousand separator dengan format Indonesia.
///
/// Contoh: 100000 → 100.000 | 1500000 → 1.500.000
///
/// Cara pakai:
/// ```dart
/// TextField(
///   inputFormatters: [ThousandSeparatorInputFormatter()],
///   keyboardType: TextInputType.number,
/// )
/// ```
///
/// Untuk parse kembali ke double:
/// ```dart
/// final amount = ThousandSeparatorInputFormatter.parse(controller.text);
/// ```
class ThousandSeparatorInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue.copyWith(text: '');
    }

    // Ambil hanya digit
    final digitsOnly = newValue.text.replaceAll(RegExp(r'[^\d]'), '');
    if (digitsOnly.isEmpty) {
      return newValue.copyWith(text: '');
    }

    // Hindari leading zeros (kecuali "0" sendiri)
    final trimmed = digitsOnly.length > 1
        ? digitsOnly.replaceFirst(RegExp('^0+'), '')
        : digitsOnly;
    if (trimmed.isEmpty) return newValue.copyWith(text: '0');

    final formatted = _addThousandDots(trimmed);

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }

  /// Format digit string dengan titik sebagai thousand separator.
  static String _addThousandDots(String digits) {
    final buffer = StringBuffer();
    final length = digits.length;

    for (int i = 0; i < length; i++) {
      // Tambah titik setiap 3 digit dari kanan (kecuali di posisi pertama)
      if (i > 0 && (length - i) % 3 == 0) {
        buffer.write('.');
      }
      buffer.write(digits[i]);
    }

    return buffer.toString();
  }

  /// Parse formatted string (dengan titik) kembali ke double.
  /// Contoh: "1.500.000" → 1500000.0
  static double parse(String formatted) {
    final digits = formatted.replaceAll('.', '').replaceAll(',', '');
    return double.tryParse(digits) ?? 0.0;
  }

  /// Format double ke string dengan thousand separator.
  /// Contoh: 1500000.0 → "1.500.000"
  static String format(double value) {
    final intValue = value.truncate();
    return _addThousandDots(intValue.toString());
  }
}