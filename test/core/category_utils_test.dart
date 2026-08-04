import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spendly/core/constants/app_constants.dart';
import 'package:spendly/core/utils/category_utils.dart';

void main() {
  group('CategoryUtils Unit Tests', () {
    test('every expense category in AppConstants has a non-default icon and color', () {
      for (final cat in AppConstants.expenseCategories) {
        final icon = CategoryUtils.getIcon(cat);
        final color = CategoryUtils.getColor(cat);
        final shortLabel = CategoryUtils.getShortLabel(cat);

        expect(icon, isNot(equals(Icons.receipt_long_rounded)), reason: 'Category $cat has default icon');
        expect(color, isNot(equals(const Color(0xFF6B7280))), reason: 'Category $cat has default color');
        expect(shortLabel, isNotEmpty, reason: 'Category $cat has empty short label');
      }
    });

    test('every income category in AppConstants has a non-default icon and color', () {
      for (final cat in AppConstants.incomeCategories) {
        final icon = CategoryUtils.getIcon(cat);
        final color = CategoryUtils.getColor(cat);
        final shortLabel = CategoryUtils.getShortLabel(cat);

        expect(icon, isNot(equals(Icons.receipt_long_rounded)), reason: 'Category $cat has default icon');
        expect(color, isNot(equals(const Color(0xFF6B7280))), reason: 'Category $cat has default color');
        expect(shortLabel, isNotEmpty, reason: 'Category $cat has empty short label');
      }
    });
  });
}
