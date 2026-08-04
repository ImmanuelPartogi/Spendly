import 'package:flutter_test/flutter_test.dart';
import 'package:spendly/features/scanner/domain/models/scanned_transaction_result.dart';
import 'package:spendly/features/scanner/presentation/screens/scan_review_screen.dart';
import 'package:spendly/features/scanner/domain/services/ocr_parser_service.dart';

void main() {
  group('OCR Scan Review Flow Unit Tests', () {
    late ScannedTransactionResult successResult;
    late ScannedTransactionResult failedResult;
    late List<ScanResultItem> initialItems;

    setUp(() {
      successResult = const ScannedTransactionResult(
        source: 'Indomaret',
        type: ScannedDocumentType.receipt,
        amount: 45000,
        description: 'Belanja harian',
        rawText: 'INDOMARET TOTAL 45.000',
        success: true,
        imagePath: '/tmp/img1.jpg',
      );

      failedResult = const ScannedTransactionResult(
        source: null,
        type: ScannedDocumentType.unknown,
        amount: null,
        description: '',
        rawText: '',
        success: false,
        errorMessage: 'Teks tidak terdeteksi',
        imagePath: '/tmp/img2.jpg',
      );

      initialItems = [
        ScanResultItem(
          result: successResult,
          imagePath: '/tmp/img1.jpg',
          isSelected: false,
        ),
        ScanResultItem(
          result: failedResult,
          imagePath: '/tmp/img2.jpg',
          isSelected: false,
        ),
      ];
    });

    test('ScanReviewNotifier initializes with provided list', () {
      final notifier = ScanReviewNotifier(initialItems);

      expect(notifier.state.length, 2);
      expect(notifier.state[0].result.source, 'Indomaret');
      expect(notifier.state[0].isSelected, isFalse);
      expect(notifier.state[1].isSelected, isFalse);
    });

    test('toggleSelection flips isSelected flag for item at index', () {
      final notifier = ScanReviewNotifier(initialItems);

      // Toggle index 0 (false -> true)
      notifier.toggleSelection(0);
      expect(notifier.state[0].isSelected, isTrue);

      // Toggle index 0 again (true -> false)
      notifier.toggleSelection(0);
      expect(notifier.state[0].isSelected, isFalse);
    });

    test('selectAll sets isSelected to true only for successful scan items', () {
      final notifier = ScanReviewNotifier(initialItems);

      notifier.selectAll();

      // Successful item is selected
      expect(notifier.state[0].isSelected, isTrue);
      // Failed item remains unselected
      expect(notifier.state[1].isSelected, isFalse);
    });

    test('updateItem updates item data and marks isEdited as true', () {
      final notifier = ScanReviewNotifier(initialItems);

      final updatedResult = successResult.copyWith(
        amount: 50000,
        source: 'Indomaret Point',
      );

      final updatedItem = notifier.state[0].copyWith(
        result: updatedResult,
      );

      notifier.updateItem(0, updatedItem);

      expect(notifier.state[0].result.amount, 50000);
      expect(notifier.state[0].result.source, 'Indomaret Point');
      expect(notifier.state[0].isEdited, isTrue);
    });

    test('Category suggestion mapping integrates correctly with OcrParserService', () {
      final receiptResult = const ScannedTransactionResult(
        source: 'Kafe Starbucks Coffee',
        type: ScannedDocumentType.receipt,
        amount: 65000,
        description: 'Kopi',
        rawText: 'KAFE STARBUCKS TOTAL 65.000',
        success: true,
      );

      final suggestedCategory = OcrParserService.suggestCategory(
        type: receiptResult.type,
        source: receiptResult.source,
      );
      expect(suggestedCategory, 'Makanan & Minuman');
    });
  });
}
