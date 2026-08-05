import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('EasyLocalization JSON Asset Unit Tests', () {
    final locales = [
      'id',
      'en',
      'ms',
      'es',
      'zh',
      'hi',
      'fr',
      'pt',
      'ja',
      'de',
      'ru',
      'ko',
      'vi',
    ];
    final Map<String, Map<String, dynamic>> jsonMap = {};

    setUpAll(() {
      for (final locale in locales) {
        final file = File('assets/translations/$locale.json');
        expect(
          file.existsSync(),
          isTrue,
          reason: 'assets/translations/$locale.json must exist',
        );
        jsonMap[locale] =
            jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
      }
    });

    test('all 13 translation files have identical key sets (100% key parity)', () {
      final baseKeys = jsonMap['id']!.keys.toSet();
      expect(baseKeys.length, greaterThan(300));

      for (final locale in locales) {
        final currentKeys = jsonMap[locale]!.keys.toSet();
        expect(
          currentKeys,
          equals(baseKeys),
          reason: '$locale.json key set must match id.json 100%',
        );
      }
    });

    test('all translation keys have non-empty values across all 13 locales', () {
      final baseKeys = jsonMap['id']!.keys;
      for (final key in baseKeys) {
        for (final locale in locales) {
          final val = jsonMap[locale]![key].toString().trim();
          expect(
            val.isNotEmpty,
            isTrue,
            reason: 'Key "$key" in $locale.json must not be empty',
          );
        }
      }
    });

    test('verifies specific core key translations in ID, EN, MS, ES, ZH, JA, KO, FR, DE', () {
      expect(jsonMap['id']!['dashboard'], 'Dashboard');
      expect(jsonMap['en']!['dashboard'], 'Dashboard');
      expect(jsonMap['ms']!['dashboard'], 'Papan Pemuka');
      expect(jsonMap['es']!['dashboard'], 'Panel Principal');

      expect(jsonMap['id']!['income'], 'Pemasukan');
      expect(jsonMap['en']!['income'], 'Income');
      expect(jsonMap['ms']!['income'], 'Pendapatan');
      expect(jsonMap['es']!['income'], 'Ingresos');
      expect(jsonMap['zh']!['income'], '收入');
      expect(jsonMap['ja']!['income'], '収入');
      expect(jsonMap['ko']!['income'], '수입');
      expect(jsonMap['fr']!['income'], 'Revenus');
      expect(jsonMap['de']!['income'], 'Einnahmen');
    });
  });
}
