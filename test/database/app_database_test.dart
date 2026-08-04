import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:spendly/core/database/app_database.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  group('AppDatabase Schema & Index Tests', () {
    test('schemaVersion is 4', () {
      expect(db.schemaVersion, 4);
    });

    test('Indexes on transactions table exist', () async {
      final result = await db.customSelect(
        "SELECT name FROM sqlite_master WHERE type='index' AND tbl_name='transactions'",
      ).get();

      final indexNames = result.map((row) => row.read<String>('name')).toList();

      expect(indexNames, contains('idx_transactions_date'));
      expect(indexNames, contains('idx_transactions_wallet'));
      expect(indexNames, contains('idx_transactions_category'));
    });
  });
}
