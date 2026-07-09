/// Tipe dokumen yang dideteksi dari hasil OCR.
enum ScannedDocumentType {
  receipt,
  salarySlip,
  unknown;

  String get label {
    switch (this) {
      case ScannedDocumentType.receipt:
        return 'receipt';
      case ScannedDocumentType.salarySlip:
        return 'salary_slip';
      case ScannedDocumentType.unknown:
        return 'unknown';
    }
  }
}

/// Hasil terstruktur dari scanning OCR sebuah gambar struk / slip gaji.
///
/// Setiap gambar yang diproses akan menghasilkan satu [ScannedTransactionResult].
/// Field [success] menandakan apakah OCR berhasil mengekstrak teks secara minimal.
class ScannedTransactionResult {
  /// Nama merchant / institusi (mis. "BCA", "Indomaret").
  final String? source;

  /// Tipe dokumen terdeteksi.
  final ScannedDocumentType type;

  /// Nominal total transaksi (Rupiah). `null` bila tidak terdeteksi.
  final double? amount;

  /// Tanggal transaksi. `null` bila tidak terdeteksi.
  final DateTime? date;

  /// Deskripsi siap-pakai untuk field note.
  final String description;

  /// Teks mentah hasil OCR (untuk debugging / fallback).
  final String rawText;

  /// Apakah OCR berhasil mengekstrak teks yang cukup.
  final bool success;

  /// Pesan error bila [success] bernilai `false`.
  final String? errorMessage;

  /// Path file gambar asli (opsional, untuk preview).
  final String? imagePath;

  const ScannedTransactionResult({
    this.source,
    required this.type,
    this.amount,
    this.date,
    required this.description,
    required this.rawText,
    required this.success,
    this.errorMessage,
    this.imagePath,
  });

  /// Apakah hasil ini valid untuk ditambahkan sebagai transaksi.
  /// Harus sukses DAN memiliki amount (user bisa isi manual bila null).
  bool get isAddable => success;

  /// Tipe sebagai string ("receipt" | "salary_slip" | "unknown").
  String get typeString => type.label;

  ScannedTransactionResult copyWith({
    String? source,
    ScannedDocumentType? type,
    double? amount,
    DateTime? date,
    String? description,
    String? rawText,
    bool? success,
    String? errorMessage,
    String? imagePath,
  }) =>
      ScannedTransactionResult(
        source: source ?? this.source,
        type: type ?? this.type,
        amount: amount ?? this.amount,
        date: date ?? this.date,
        description: description ?? this.description,
        rawText: rawText ?? this.rawText,
        success: success ?? this.success,
        errorMessage: errorMessage ?? this.errorMessage,
        imagePath: imagePath ?? this.imagePath,
      );
}