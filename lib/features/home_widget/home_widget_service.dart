import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';
import 'package:intl/intl.dart';

/// Service untuk mengupdate homescreen widget dari Flutter.
///
/// Panggil [HomeWidgetService.update] setiap kali ada transaksi baru
/// atau saat app di-foreground.
class HomeWidgetService {
  HomeWidgetService._();

  static const _appGroupId = 'group.com.harimokkar.spendly'; // iOS App Group
  static const _qualifiedAndroid = 'com.harimokkar.spendly.SpendlyWidget';
  static const _qualifiedIos = 'SpendlyWidget';

  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;
    await HomeWidget.setAppGroupId(_appGroupId);
    await HomeWidget.registerInteractivityCallback(_backgroundCallback);
    _initialized = true;
  }

  /// Update data widget dan trigger refresh.
  static Future<void> update({
    required double totalBalance,
    required double todayExpense,
  }) async {
    final fmt = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    final now = DateTime.now();
    final timeStr =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    await Future.wait([
      HomeWidget.saveWidgetData('widget_balance', fmt.format(totalBalance)),
      HomeWidget.saveWidgetData(
          'widget_today_expense', fmt.format(todayExpense),),
      HomeWidget.saveWidgetData('widget_last_updated', timeStr),
    ]);

    await HomeWidget.updateWidget(
      androidName: _qualifiedAndroid,
      iOSName: _qualifiedIos,
    );
  }

  /// Reset widget ke nilai kosong.
  static Future<void> reset() => update(
        totalBalance: 0,
        todayExpense: 0,
      );
}

/// Background callback — dipanggil saat user tap tombol + di widget.
@pragma('vm:entry-point')
Future<void> _backgroundCallback(Uri? uri) async {
  if (uri?.host == 'add_transaction') {
    // Navigate ke AddTransactionScreen.
    // Gunakan GlobalKey<NavigatorState> atau deep link di MaterialApp.
    debugPrint('[HomeWidget] add_transaction triggered via widget');
  }
}

/// Mixin untuk widget/screen yang perlu update homescreen widget
/// setelah setiap perubahan data.
mixin HomeWidgetUpdater<T extends StatefulWidget> on State<T> {
  Future<void> refreshHomeWidget({
    required double balance,
    required double todayExpense,
  }) async {
    try {
      await HomeWidgetService.update(
        totalBalance: balance,
        todayExpense: todayExpense,
      );
    } catch (e) {
      debugPrint('[HomeWidget] Update failed: $e');
    }
  }
}
