import 'package:flutter_test/flutter_test.dart';
import 'package:spendly/features/scanner/domain/models/scanned_transaction_result.dart';
import 'package:spendly/features/scanner/domain/services/ocr_parser_service.dart';

void main() {
  group('OcrParserService Category Suggestion Tests', () {
    test('salarySlip type returns Gaji', () {
      final category = OcrParserService.suggestCategory(
        type: ScannedDocumentType.salarySlip,
        source: 'PT Jaya Abadi',
      );
      expect(category, 'Gaji');
    });

    test('Indomaret or Tokopedia source returns Belanja', () {
      expect(
        OcrParserService.suggestCategory(
          type: ScannedDocumentType.receipt,
          source: 'INDOMARET POINT',
        ),
        'Belanja',
      );
      expect(
        OcrParserService.suggestCategory(
          type: ScannedDocumentType.receipt,
          source: 'Shopee Official Store',
        ),
        'Belanja',
      );
    });

    test('Restaurant or cafe source returns Makanan & Minuman', () {
      expect(
        OcrParserService.suggestCategory(
          type: ScannedDocumentType.receipt,
          source: 'Kafe Kenangan',
        ),
        'Makanan & Minuman',
      );
    });

    test('Gojek or Grab source returns Transportasi', () {
      expect(
        OcrParserService.suggestCategory(
          type: ScannedDocumentType.receipt,
          source: 'Gojek Ride',
        ),
        'Transportasi',
      );
    });

    test('Unknown merchant returns Lainnya', () {
      expect(
        OcrParserService.suggestCategory(
          type: ScannedDocumentType.receipt,
          source: 'Toko Kelontong Pak Ali',
        ),
        'Lainnya',
      );
    });
  });
}
