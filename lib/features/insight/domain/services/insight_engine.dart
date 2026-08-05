import '../../../transactions/domain/repositories/transaction_repository.dart';
import '../../../budget/domain/repositories/budget_repository.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/category_utils.dart';
import '../../../../core/utils/date_formatter.dart';
import 'package:easy_localization/easy_localization.dart';

class InsightData {
  final String type;
  final String message;
  final String? translationKey;
  final Map<String, String>? namedArgs;
  final String emoji;
  final bool isWarning;

  const InsightData({
    required this.type,
    required this.message,
    this.translationKey,
    this.namedArgs,
    required this.emoji,
    this.isWarning = false,
  });

  String getLocalizedMessage() {
    if (translationKey != null) {
      return translationKey!.tr(namedArgs: namedArgs);
    }
    return message;
  }
}

class InsightEngine {
  final TransactionRepository _txRepo;
  final BudgetRepository _budgetRepo;
  InsightEngine(this._txRepo, this._budgetRepo);

  Future<List<InsightData>> generateInsights() async {
    final insights = <InsightData>[];
    final now = DateTime.now();
    final year = now.year;
    final month = now.month;

    final categoryTotals = await _txRepo.getCategoryTotals(year, month, 'expense');
    final totalExpense = await _txRepo.getTotalByTypeAndMonth('expense', year, month);

    // Kategori terbesar
    if (categoryTotals.isNotEmpty && totalExpense > 0) {
      final sorted = categoryTotals.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      final top = sorted.first;
      final pct = ((top.value / totalExpense) * 100).round();
      final catLocalized = CategoryUtils.getLocalizedName(top.key);
      insights.add(InsightData(
        type: 'category_spend',
        emoji: _categoryEmoji(top.key),
        translationKey: 'insight_category_spend',
        namedArgs: {'pct': '$pct', 'category': catLocalized},
        message: '$pct% pengeluaran bulan ini berasal dari kategori $catLocalized',
      ));
    }

    // Hari dengan pengeluaran tertinggi
    final weekdayTotals = await _txRepo.getWeekdayTotals(year, month, 'expense');
    if (weekdayTotals.values.any((v) => v > 0)) {
      final maxEntry = weekdayTotals.entries
          .reduce((a, b) => a.value > b.value ? a : b);
      final dayLocalized = DateFormatter.formatWeekdayName(maxEntry.key);
      insights.add(InsightData(
        type: 'highest_day',
        emoji: '📅',
        translationKey: 'insight_highest_day',
        namedArgs: {'day': dayLocalized},
        message: 'Kamu paling banyak belanja di hari $dayLocalized bulan ini',
      ));
    }

    // Perbandingan dengan bulan lalu
    final prevMonth = month == 1 ? 12 : month - 1;
    final prevYear  = month == 1 ? year - 1 : year;
    final prevExpense = await _txRepo.getTotalByTypeAndMonth('expense', prevYear, prevMonth);
    if (prevExpense > 0 && totalExpense > 0) {
      final pct = (((totalExpense - prevExpense) / prevExpense) * 100)
          .roundToDouble();
      if (pct > 0) {
        insights.add(InsightData(
          type: 'spend_trend',
          emoji: '📈',
          translationKey: 'insight_trend_up',
          namedArgs: {'pct': pct.abs().toStringAsFixed(0)},
          message: 'Pengeluaran naik ${pct.abs().toStringAsFixed(0)}% dibanding bulan lalu',
          isWarning: pct > 20,
        ));
      } else if (pct < 0) {
        insights.add(InsightData(
          type: 'spend_trend',
          emoji: '📉',
          translationKey: 'insight_trend_down',
          namedArgs: {'pct': pct.abs().toStringAsFixed(0)},
          message: 'Pengeluaran turun ${pct.abs().toStringAsFixed(0)}% dibanding bulan lalu, pertahankan!',
        ));
      }
    }

    // Peringatan anggaran
    final budgets = await _budgetRepo.getAllBudgets();
    for (final budget in budgets) {
      final spent = categoryTotals[budget.category] ?? 0;
      final pct = budget.limitAmount > 0 ? spent / budget.limitAmount : 0.0;
      final catLocalized = CategoryUtils.getLocalizedName(budget.category);
      if (pct >= 1.0) {
        insights.add(InsightData(
          type: 'budget_warning',
          emoji: '🚨',
          isWarning: true,
          translationKey: 'insight_budget_exceeded',
          namedArgs: {
            'category': catLocalized,
            'spent': CurrencyFormatter.formatCompact(spent),
            'limit': CurrencyFormatter.formatCompact(budget.limitAmount),
          },
          message:
              'Anggaran $catLocalized sudah terlampaui! '
              '${CurrencyFormatter.formatCompact(spent)} / '
              '${CurrencyFormatter.formatCompact(budget.limitAmount)}',
        ));
      } else if (pct >= 0.8) {
        insights.add(InsightData(
          type: 'budget_warning',
          emoji: '⚠️',
          isWarning: true,
          translationKey: 'insight_budget_80',
          namedArgs: {
            'category': catLocalized,
            'remaining': CurrencyFormatter.formatCompact(budget.limitAmount - spent),
          },
          message:
              'Anggaran $catLocalized sudah terpakai 80%. '
              'Sisa ${CurrencyFormatter.formatCompact(budget.limitAmount - spent)}',
        ));
      }
    }

    // Rasio tabungan
    final totalIncome = await _txRepo.getTotalByTypeAndMonth('income', year, month);
    if (totalIncome > 0 && totalExpense > 0) {
      final ratio = totalExpense / totalIncome;
      if (ratio <= 0.9) {
        final saved = totalIncome - totalExpense;
        insights.add(InsightData(
          type: 'savings',
          emoji: '🏦',
          translationKey: 'insight_savings_success',
          namedArgs: {'saved': CurrencyFormatter.formatCompact(saved)},
          message: 'Kamu berhasil menabung ${CurrencyFormatter.formatCompact(saved)} bulan ini!',
        ));
      } else {
        insights.add(InsightData(
          type: 'balance_warning',
          emoji: '💸',
          isWarning: ratio > 1.0,
          translationKey: 'insight_balance_warning',
          namedArgs: {'pct': '${(ratio * 100).round()}'},
          message: 'Kamu sudah menggunakan ${(ratio * 100).round()}% dari pemasukan bulan ini',
        ));
      }
    }

    return insights;
  }

  String _categoryEmoji(String category) {
    return '💳';
  }
}