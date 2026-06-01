import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

/// Service OCR menggunakan Google ML Kit Text Recognition.
///
/// Cara pakai:
/// ```dart
/// final text  = await OcrService.extractText(imageFile);
/// final total = OcrService.extractTotal(text);
/// final date  = OcrService.extractDate(text);
/// ```
class OcrService {
  OcrService._();

  static final _recognizer =
      TextRecognizer(script: TextRecognitionScript.latin);

  // ─── Core ─────────────────────────────────────────────────────────────────

  /// Ekstrak seluruh teks dari gambar menggunakan ML Kit.
  static Future<String> extractText(File imageFile) async {
    final inputImage = InputImage.fromFile(imageFile);
    final result = await _recognizer.processImage(inputImage);
    return result.text;
  }

  // ─── Parsers ──────────────────────────────────────────────────────────────

  /// Parse total nominal dari teks OCR.
  ///
  /// Mendukung format:
  ///   TOTAL : Rp 85.000
  ///   JUMLAH   85000
  ///   GRAND TOTAL  Rp85.000
  static double? extractTotal(String text) {
    final patterns = [
      // "TOTAL / GRAND TOTAL / JUMLAH / BAYAR / AMOUNT" diikuti angka
      RegExp(
        r'(?:TOTAL|GRAND\s+TOTAL|JUMLAH|BAYAR|AMOUNT|SUBTOTAL)'
        r'\s*:?\s*(?:RP\.?\s*)?(\d[\d.,]*)',
        caseSensitive: false,
      ),
      // Angka besar di akhir baris (fallback)
      RegExp(
        r'(?:RP\.?\s*)?(\d{3,}(?:[.,]\d{3})*(?:[.,]\d{0,2})?)\s*$',
        multiLine: true,
      ),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        final raw = match.group(1)!.replaceAll('.', '').replaceAll(',', '');
        final value = double.tryParse(raw);
        // Abaikan nilai terlalu kecil (bukan total belanja)
        if (value != null && value >= 100) return value;
      }
    }
    return null;
  }

  /// Parse tanggal dari teks OCR.
  ///
  /// Mendukung format: dd/mm/yyyy, dd-mm-yyyy, dd.mm.yyyy
  static DateTime? extractDate(String text) {
    final pattern = RegExp(
      r'(\d{1,2})[/\-.](\d{1,2})[/\-.](\d{2,4})',
    );
    for (final match in pattern.allMatches(text)) {
      final day = int.tryParse(match.group(1)!);
      final month = int.tryParse(match.group(2)!);
      var year = int.tryParse(match.group(3)!);

      if (year != null && year < 100) year += 2000;
      if (day == null || month == null || year == null) continue;
      if (month < 1 || month > 12) continue;
      if (day < 1 || day > 31) continue;

      try {
        return DateTime(year, month, day);
      } catch (_) {
        continue;
      }
    }
    return null;
  }

  /// Parse nama merchant dari baris teks pertama yang bermakna.
  static String? extractMerchant(String text) {
    final lines = text
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.length > 2)
        .toList();
    return lines.isNotEmpty ? lines.first : null;
  }

  /// Tutup recognizer saat tidak dibutuhkan lagi.
  /// Panggil di dispose() layar yang menggunakannya.
  static void dispose() => _recognizer.close();
}
