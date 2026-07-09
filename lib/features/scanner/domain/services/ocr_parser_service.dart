import 'package:intl/intl.dart';

import '../models/scanned_transaction_result.dart';

/// Service yang menerima teks mentah hasil OCR dan mengembalikan
/// [ScannedTransactionResult] yang terstruktur.
///
/// Logika parsing:
/// 1. Deteksi tipe dokumen (receipt / salary_slip / unknown)
/// 2. Deteksi source / merchant
/// 3. Ekstraksi amount (Rupiah)
/// 4. Ekstraksi tanggal
/// 5. Generate deskripsi
class OcrParserService {
  OcrParserService._();

  // ── Keyword maps ─────────────────────────────────────────────────────────────

  static const _bankKeywords = [
    'BCA', 'BNI', 'BRI', 'Mandiri', 'CIMB', 'Danamon', 'BSI', 'Permata',
  ];

  static const _retailKeywords = [
    'Indomaret', 'Alfamart', 'Alfamidi', 'Lawson', 'Circle K',
    'Giant', 'Hypermart', 'Carrefour', 'Transmart',
  ];

  static const _ecommerceKeywords = [
    'Tokopedia', 'Shopee', 'Lazada', 'Bukalapak', 'Traveloka',
    'Gojek', 'Grab', 'OVO', 'Dana', 'GoPay',
  ];

  static const _salaryKeywords = [
    'slip gaji', 'payslip', 'gaji pokok', 'take home pay', 'tunjangan',
    'potongan', 'bpjs', 'thr', 'salary', 'payroll', 'gaji bersih',
  ];

  static const _receiptKeywords = [
    'total', 'subtotal', 'kasir', 'terima kasih', 'thank you',
    'no. struk', 'nota', 'invoice', 'struk', 'receipt',
  ];

  static const _monthNamesId = [
    'januari', 'februari', 'maret', 'april', 'mei', 'juni',
    'juli', 'agustus', 'september', 'oktober', 'november', 'desember',
  ];

  static const _monthAbbrId = [
    'jan', 'feb', 'mar', 'apr', 'mei', 'jun',
    'jul', 'agu', 'sep', 'okt', 'nov', 'des',
  ];

  static const _monthNamesEn = [
    'january', 'february', 'march', 'april', 'may', 'june',
    'july', 'august', 'september', 'october', 'november', 'december',
  ];

  static const _monthAbbrEn = [
    'jan', 'feb', 'mar', 'apr', 'may', 'jun',
    'jul', 'aug', 'sep', 'oct', 'nov', 'dec',
  ];

  // ─── Public API ──────────────────────────────────────────────────────────────

  /// Parse teks OCR menjadi [ScannedTransactionResult].
  ///
  /// Bila [rawText] kosong / terlalu pendek, return hasil dengan
  /// [ScannedTransactionResult.success] = `false`.
  /// Setiap exception selama parsing ditangkap dan dikembalikan sebagai
  /// hasil gagal dengan pesan error dalam Bahasa Indonesia.
  static ScannedTransactionResult parse(
    String rawText, {
    String? imagePath,
  }) {
    try {
      final text = rawText.trim();

      if (text.isEmpty || text.length < 5) {
        return ScannedTransactionResult(
          source: null,
          type: ScannedDocumentType.unknown,
          amount: null,
          date: null,
          description: '',
          rawText: rawText,
          success: false,
          errorMessage: 'Teks tidak terdeteksi. Pastikan gambar cukup jelas.',
          imagePath: imagePath,
        );
      }

      final lower = text.toLowerCase();
      final lines = _splitLines(text);

      final type = _detectType(lower);
      final source = _detectSource(text, lower, lines);
      final amount = _extractAmount(text, lower, type);
      final date = _extractDate(text, lower, type);
      final description = _generateDescription(type, source, text, date);

      return ScannedTransactionResult(
        source: source,
        type: type,
        amount: amount,
        date: date,
        description: description,
        rawText: rawText,
        success: true,
        errorMessage: null,
        imagePath: imagePath,
      );
    } catch (e) {
      return ScannedTransactionResult(
        source: null,
        type: ScannedDocumentType.unknown,
        amount: null,
        date: null,
        description: '',
        rawText: rawText,
        success: false,
        errorMessage: 'Gagal mengurai teks hasil pindaian: $e',
        imagePath: imagePath,
      );
    }
  }

  // ─── 3a. Source / Merchant Detection ─────────────────────────────────────────

  static String _detectSource(String text, String lower, List<String> lines) {
    // Bank keywords
    for (final kw in _bankKeywords) {
      if (lower.contains(kw.toLowerCase())) return kw;
    }
    // Retail keywords
    for (final kw in _retailKeywords) {
      if (lower.contains(kw.toLowerCase())) return kw;
    }
    // E-commerce keywords
    for (final kw in _ecommerceKeywords) {
      if (lower.contains(kw.toLowerCase())) return kw;
    }

    // Fallback: first line that is entirely uppercase or Title Case.
    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.length < 2) continue;
      // Skip lines that are mostly digits / symbols.
      if (RegExp(r'^[\d\s\W]+$').hasMatch(trimmed)) continue;

      // Case 1: entirely uppercase (mis. "INDOMARET", "ALFAMART").
      if (trimmed.toUpperCase() == trimmed &&
          trimmed.toLowerCase() != trimmed) {
        return trimmed;
      }

      // Case 2: Title Case — setiap kata dimulai huruf besar.
      final words = trimmed.split(RegExp(r'\s+'));
      final isTitleCase = words.every((w) {
        if (w.isEmpty) return false;
        return w[0].toUpperCase() == w[0] &&
            w[0].toLowerCase() != w[0];
      });
      if (isTitleCase) {
        return words.take(3).join(' ');
      }
    }
    return 'Tidak Diketahui';
  }

  // ─── 3b. Document Type Detection ─────────────────────────────────────────────

  static ScannedDocumentType _detectType(String lowerText) {
    // Salary slip first (lebih spesifik)
    for (final kw in _salaryKeywords) {
      if (lowerText.contains(kw.toLowerCase())) {
        return ScannedDocumentType.salarySlip;
      }
    }
    // Receipt
    for (final kw in _receiptKeywords) {
      if (lowerText.contains(kw.toLowerCase())) {
        return ScannedDocumentType.receipt;
      }
    }
    return ScannedDocumentType.unknown;
  }

  // ─── 3c. Amount Extraction ───────────────────────────────────────────────────

  static double? _extractAmount(
    String text,
    String lowerText,
    ScannedDocumentType type,
  ) {
    switch (type) {
      case ScannedDocumentType.salarySlip:
        return _extractSalaryAmount(text, lowerText);
      case ScannedDocumentType.receipt:
        return _extractReceiptAmount(text, lowerText);
      case ScannedDocumentType.unknown:
        // Fallback: largest numeric value in entire text.
        return _largestNumericValue(text);
    }
  }

  static double? _extractReceiptAmount(String text, String lowerText) {
    final lines = _splitLines(text);
    double? best;

    // Cari baris mengandung "TOTAL" / "GRAND TOTAL"
    for (var i = 0; i < lines.length; i++) {
      final lowerLine = lines[i].toLowerCase();
      if (lowerLine.contains('grand total') ||
          lowerLine.contains('total bayar') ||
          lowerLine.contains('total')) {
        final onLine = parseRupiahAmount(lines[i]);
        if (onLine != null && (best == null || onLine > best)) {
          best = onLine;
        }
        // Cek baris di bawahnya juga (kadang angka ada di baris terpisah).
        if (i + 1 < lines.length) {
          final below = parseRupiahAmount(lines[i + 1]);
          if (below != null && (best == null || below > best)) {
            best = below;
          }
        }
      }
    }

    if (best != null) return best;

    // Fallback: angka besar di akhir baris mana pun.
    final lineEnd = RegExp(
      r'(?:rp\.?\s*)?(\d{1,3}(?:[.,]\d{3})*(?:[.,]\d{1,2})?)\s*$',
      multiLine: true,
    );
    for (final m in lineEnd.allMatches(text)) {
      final v = parseRupiahAmount(m.group(1) ?? '');
      if (v != null && v >= 100 && (best == null || v > best)) best = v;
    }

    // Fallback terakhir: nilai numerik terbesar.
    best ??= _largestNumericValue(text);
    return best;
  }

  static double? _extractSalaryAmount(String text, String lowerText) {
    final lines = _splitLines(text);
    final salaryMarkers = [
      'take home pay',
      'gaji bersih',
      'jumlah diterima',
      'total gaji',
      'pendapatan',
      'penghasilan',
    ];

    double? best;
    for (var i = 0; i < lines.length; i++) {
      final lowerLine = lines[i].toLowerCase();
      for (final marker in salaryMarkers) {
        if (lowerLine.contains(marker)) {
          final onLine = parseRupiahAmount(lines[i]);
          if (onLine != null && (best == null || onLine > best)) {
            best = onLine;
          }
          if (i + 1 < lines.length) {
            final below = parseRupiahAmount(lines[i + 1]);
            if (below != null && (best == null || below > best)) {
              best = below;
            }
          }
        }
      }
    }

    if (best != null) return best;
    // Fallback: nilai numerik terbesar.
    return _largestNumericValue(text);
  }

  /// Parse string nominal Rupiah → double.
  ///
  /// Mendukung:
  ///   - "Rp 85.000"  → 85000
  ///   - "IDR 85,000" → 85000
  ///   - "1.250.000"  → 1250000
  ///   - "85000"      → 85000
  static double? parseRupiahAmount(String text) {
    if (text.isEmpty) return null;
    var cleaned = text
        .replaceAll('Rp', '')
        .replaceAll('RP', '')
        .replaceAll('IDR', '')
        .replaceAll('idr', '')
        .replaceAll(' ', '')
        .trim();

    // Tangani format "85.000" (Indonesia) dan "85,000" (EN).
    // Strategi:
    //   - Jika ada separator ribuan yang konsisten, hapus.
    //   - Jika ada satu separator diikuti 2 digit terakhir → desimal.
    final hasComma = cleaned.contains(',');
    final hasDot = cleaned.contains('.');

    if (hasComma && hasDot) {
      // Asumsi: dot = ribuan, comma = desimal (id_ID).
      cleaned = cleaned.replaceAll('.', '').replaceAll(',', '.');
    } else if (hasDot) {
      // Titik sebagai pemisah ribuan (format id_ID).
      // Contoh: "85.000", "1.250.000".
      cleaned = cleaned.replaceAll('.', '');
    } else if (hasComma) {
      final lastComma = cleaned.lastIndexOf(',');
      final afterComma = cleaned.substring(lastComma + 1);
      if (afterComma.length <= 2 && int.tryParse(afterComma) != null) {
        cleaned = cleaned.replaceAll(',', '.');
      } else {
        cleaned = cleaned.replaceAll(',', '');
      }
    }

    final value = double.tryParse(cleaned);
    if (value == null) return null;
    // Abaikan nilai terlalu kecil (bukan nominal transaksi nyata).
    if (value < 100) return null;
    return value;
  }

  static double? _largestNumericValue(String text) {
    final candidates = <double>[];
    final pattern = RegExp(r'\d{1,3}(?:[.,]\d{3})*(?:[.,]\d{1,2})?');
    for (final m in pattern.allMatches(text)) {
      final v = parseRupiahAmount(m.group(0)!);
      if (v != null && v >= 100) candidates.add(v);
    }
    if (candidates.isEmpty) return null;
    candidates.sort();
    return candidates.last;
  }

  // ─── 3d. Date Extraction ─────────────────────────────────────────────────────

  static DateTime? _extractDate(
    String text,
    String lowerText,
    ScannedDocumentType type,
  ) {
    // Format dd/MM/yyyy, dd-MM-yyyy, dd.MM.yyyy
    final numericDate = RegExp(r'(\d{1,2})[/\-.](\d{1,2})[/\-.](\d{2,4})');
    for (final m in numericDate.allMatches(text)) {
      final parsed = _buildDate(m.group(1), m.group(2), m.group(3));
      if (parsed != null) return parsed;
    }

    // Format dd MM yyyy (spasi sebagai pemisah, mis. "15 06 2025")
    final spaceDate = RegExp(r'(\d{1,2})\s+(\d{1,2})\s+(\d{4})');
    for (final m in spaceDate.allMatches(text)) {
      final parsed = _buildDate(m.group(1), m.group(2), m.group(3));
      if (parsed != null) return parsed;
    }

    // Format yyyy-MM-dd (ISO)
    final isoDate = RegExp(r'(\d{4})-(\d{1,2})-(\d{1,2})');
    for (final m in isoDate.allMatches(text)) {
      final parsed = _buildDate(m.group(3), m.group(2), m.group(1));
      if (parsed != null) return parsed;
    }

    // Format "d MMM yyyy" (mis. "15 Jun 2025", "15 Juni 2025")
    final namedDate = RegExp(
      r'(\d{1,2})\s+([A-Za-zÀ-ÿ]+)\s+(\d{4})',
    );
    for (final m in namedDate.allMatches(text)) {
      final month = _monthFromName(m.group(2)!);
      if (month != null) {
        final parsed = _buildDate(m.group(1), '$month', m.group(3));
        if (parsed != null) return parsed;
      }
    }

    // Untuk salary slip: cari "Periode" / "Bulan" + bulan/tahun.
    if (type == ScannedDocumentType.salarySlip) {
      final periodMatch = RegExp(
        r'(?:periode|bulan|month|per)\s*:?\s*([A-Za-zÀ-ÿ]+)\s*(\d{4})',
        caseSensitive: false,
      ).firstMatch(text);
      if (periodMatch != null) {
        final month = _monthFromName(periodMatch.group(1)!);
        final year = int.tryParse(periodMatch.group(2)!);
        if (month != null && year != null) {
          return DateTime(year, month, 1);
        }
      }
    }

    return null;
  }

  static int? _monthFromName(String name) {
    final lower = name.toLowerCase();
    final idx1 = _monthNamesId.indexOf(lower);
    if (idx1 >= 0) return idx1 + 1;
    final idx2 = _monthAbbrId.indexOf(lower);
    if (idx2 >= 0) return idx2 + 1;
    final idx3 = _monthNamesEn.indexOf(lower);
    if (idx3 >= 0) return idx3 + 1;
    final idx4 = _monthAbbrEn.indexOf(lower);
    if (idx4 >= 0) return idx4 + 1;
    return null;
  }

  static DateTime? _buildDate(String? dayStr, String? monthStr, String? yearStr) {
    final day = int.tryParse(dayStr ?? '');
    final month = int.tryParse(monthStr ?? '');
    var year = int.tryParse(yearStr ?? '');
    if (day == null || month == null || year == null) return null;
    if (year < 100) year += 2000;
    if (month < 1 || month > 12) return null;
    if (day < 1 || day > 31) return null;
    try {
      return DateTime(year, month, day);
    } catch (_) {
      return null;
    }
  }

  // ─── 3e. Description Generation ──────────────────────────────────────────────

  static String _generateDescription(
    ScannedDocumentType type,
    String? source,
    String text,
    DateTime? date,
  ) {
    switch (type) {
      case ScannedDocumentType.receipt:
        final items = _extractReceiptItems(text);
        final src = source ?? 'Tidak Diketahui';
        if (items.isEmpty) return 'Belanja di $src';
        if (items.length <= 2) {
          return 'Belanja di $src: ${items.join(', ')}';
        }
        final extra = items.length - 2;
        return 'Belanja di $src: ${items.take(2).join(', ')}, +$extra lainnya';
      case ScannedDocumentType.salarySlip:
        final src = source ?? 'Tidak Diketahui';
        if (date != null) {
          final monthLabel = DateFormat('MMMM yyyy', 'id_ID').format(date);
          return 'Slip Gaji $src — $monthLabel';
        }
        return 'Slip Gaji $src';
      case ScannedDocumentType.unknown:
        final src = source ?? 'Tidak Diketahui';
        return 'Transaksi dari $src';
    }
  }

  /// Ekstrak hingga 3 nama item dari body struk (baris antara header dan TOTAL).
  static List<String> _extractReceiptItems(String text) {
    final lines = _splitLines(text);
    final items = <String>[];
    var foundTotal = false;

    // Identifikasi indeks baris "TOTAL".
    int totalIndex = -1;
    for (var i = 0; i < lines.length; i++) {
      if (lines[i].toLowerCase().contains('total') &&
          !lines[i].toLowerCase().contains('subtotal')) {
        totalIndex = i;
        foundTotal = true;
        break;
      }
    }

    // Body = baris setelah beberapa header awal dan sebelum TOTAL.
    final start = 2; // skip 2 baris header kasar.
    final end = foundTotal && totalIndex > start ? totalIndex : lines.length;

    for (var i = start; i < end; i++) {
      final line = lines[i].trim();
      if (line.length < 3) continue;
      // Skip baris yang murni angka / tanggal / harga.
      if (RegExp(r'^[\d\s\W]+$').hasMatch(line)) continue;
      // Skip baris yang mengandung keyword struk.
      final lower = line.toLowerCase();
      if (_receiptKeywords.any((k) => lower.contains(k.toLowerCase()))) {
        continue;
      }
      // Ambil bagian sebelum angka harga di akhir baris.
      final namePart = line.split(RegExp(r'\s{2,}|\t')).first.trim();
      // Buang trailing qty/price patterns.
      final cleaned = namePart.replaceAll(RegExp(r'\s*\d+\s*x?\s*$', caseSensitive: false), '').trim();
      if (cleaned.length < 2) continue;
      // Hindari duplikat.
      final lowerCleaned = cleaned.toLowerCase();
      if (items.any((e) => e.toLowerCase() == lowerCleaned)) continue;
      items.add(cleaned);
      if (items.length >= 5) break; // ambil beberapa untuk filtering.
    }
    return items.take(3).toList();
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────────

  static List<String> _splitLines(String text) {
    return text
        .split(RegExp(r'[\r\n]+'))
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();
  }
}