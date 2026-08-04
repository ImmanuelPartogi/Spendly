import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';

import '../models/scanned_transaction_result.dart';
import 'ocr_parser_service.dart';

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
  ///
  /// Setiap error ML Kit ditangkap dan dikembalikan sebagai string kosong.
  /// Method ini tidak pernah melempar exception ke pemanggil.
  static Future<String> extractText(File imageFile) async {
    try {
      final inputImage = InputImage.fromFile(imageFile);
      final result = await _recognizer.processImage(inputImage);
      return result.text;
    } catch (e) {
      // Gagal OCR — kembalikan string kosong agar caller tetap aman.
      return '';
    }
  }

  // ─── Multi-Image Batch Scan ────────────────────────────────────────────────

  /// Scan satu gambar → [ScannedTransactionResult] terstruktur.
  ///
  /// Membungkus ML Kit + [OcrParserService]. Setiap error ML Kit ditangkap
  /// dan dikembalikan sebagai hasil [ScannedTransactionResult.success] = false.
  static Future<ScannedTransactionResult> scanSingleImage(
      File imageFile,) async {
    try {
      final rawText = await extractText(imageFile);
      return OcrParserService.parse(rawText, imagePath: imageFile.path);
    } catch (e) {
      return ScannedTransactionResult(
        source: null,
        type: ScannedDocumentType.unknown,
        amount: null,
        date: null,
        description: '',
        rawText: '',
        success: false,
        errorMessage: 'Gagal memproses gambar: $e',
        imagePath: imageFile.path,
      );
    }
  }

  /// Scan banyak gambar secara sekuensial.
  ///
  /// [onProgress] dipanggil setiap kali satu gambar selesai diproses dengan
  /// parameter (indexSelesai, total, hasilGambarIni). Pemrosesan sekuensial
  /// untuk menghindari tekanan memori pada perangkat.
  static Future<List<ScannedTransactionResult>> scanMultipleImages(
    List<XFile> images, {
    void Function(int done, int total, ScannedTransactionResult result)?
        onProgress,
  }) async {
    final results = <ScannedTransactionResult>[];
    final total = images.length;

    for (var i = 0; i < total; i++) {
      final xfile = images[i];
      try {
        final file = File(xfile.path);
        final rawText = await extractText(file);
        final parsed =
            OcrParserService.parse(rawText, imagePath: xfile.path);
        results.add(parsed);
        onProgress?.call(i + 1, total, parsed);
      } catch (e) {
        final failed = ScannedTransactionResult(
          source: null,
          type: ScannedDocumentType.unknown,
          amount: null,
          date: null,
          description: '',
          rawText: '',
          success: false,
          errorMessage: 'Gagal memproses gambar: $e',
          imagePath: xfile.path,
        );
        results.add(failed);
        onProgress?.call(i + 1, total, failed);
      }
    }

    return results;
  }

  /// Tutup recognizer saat tidak dibutuhkan lagi.
  /// Panggil di dispose() layar yang menggunakannya.
  static void dispose() => _recognizer.close();
}