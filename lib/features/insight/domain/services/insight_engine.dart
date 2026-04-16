import '../../../transactions/domain/repositories/transaction_repository.dart';
import '../../../budget/domain/repositories/budget_repository.dart';
import '../../../../core/utils/currency_formatter.dart';

class InsightData {
  final String type;
  final String message;
  final String emoji;
  final bool isWarning;

  const InsightData({
    required this.type, required this.message,
    required this.emoji, this.isWarning = false,
  });
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

    if (categoryTotals.isNotEmpty && totalExpense > 0) {
      final sorted = categoryTotals.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
      final top = sorted.first;
      final pct = ((top.value / totalExpense) * 100).round();
      insights.add(InsightData(
        type: 'category_spend', emoji: _categoryEmoji(top.key),
        message: '$pct% of this month\'s spending goes to ${top.key}',
      ));
    }

    final weekdayTotals = await _txRepo.getWeekdayTotals(year, month, 'expense');
    if (weekdayTotals.values.any((v) => v > 0)) {
      final maxEntry = weekdayTotals.entries.reduce((a, b) => a.value > b.value ? a : b);
      insights.add(InsightData(
        type: 'highest_day', emoji: '📅',
        message: 'You spend the most on ${_weekdayName(maxEntry.key)}s this month',
      ));
    }

    final prevMonth = month == 1 ? 12 : month - 1;
    final prevYear = month == 1 ? year - 1 : year;
    final prevExpense = await _txRepo.getTotalByTypeAndMonth('expense', prevYear, prevMonth);
    if (prevExpense > 0 && totalExpense > 0) {
      final pct = (((totalExpense - prevExpense) / prevExpense) * 100).roundToDouble();
      if (pct > 0) {
        insights.add(InsightData(
          type: 'spend_trend', emoji: '📈',
          message: 'Spending is up ${pct.abs().toStringAsFixed(0)}% from last month',
          isWarning: pct > 20,
        ));
      } else if (pct < 0) {
        insights.add(InsightData(
          type: 'spend_trend', emoji: '📉',
          message: 'Great! Spending is down ${pct.abs().toStringAsFixed(0)}% from last month',
        ));
      }
    }

    final budgets = await _budgetRepo.getAllBudgets();
    for (final budget in budgets) {
      final spent = categoryTotals[budget.category] ?? 0;
      final pct = budget.limitAmount > 0 ? spent / budget.limitAmount : 0.0;
      if (pct >= 1.0) {
        insights.add(InsightData(
          type: 'budget_warning', emoji: '🚨', isWarning: true,
          message: '${budget.category} budget exceeded! ${CurrencyFormatter.formatCompact(spent)} / ${CurrencyFormatter.formatCompact(budget.limitAmount)}',
        ));
      } else if (pct >= 0.8) {
        insights.add(InsightData(
          type: 'budget_warning', emoji: '⚠️', isWarning: true,
          message: '${budget.category} budget is 80% used. ${CurrencyFormatter.formatCompact(budget.limitAmount - spent)} left',
        ));
      }
    }

    final totalIncome = await _txRepo.getTotalByTypeAndMonth('income', year, month);
    if (totalIncome > 0 && totalExpense > 0) {
      final ratio = totalExpense / totalIncome;
      if (ratio <= 0.9) {
        final saved = totalIncome - totalExpense;
        insights.add(InsightData(
          type: 'savings', emoji: '🏦',
          message: 'You\'ve saved ${CurrencyFormatter.formatCompact(saved)} so far this month!',
        ));
      } else {
        insights.add(InsightData(
          type: 'balance_warning', emoji: '💸', isWarning: ratio > 1.0,
          message: 'You\'ve spent ${(ratio * 100).round()}% of your income this month',
        ));
      }
    }

    return insights;
  }

  String _categoryEmoji(String category) {
    const emojis = {
      'Food':'🍔','Transport':'🚗','Shopping':'🛍️','Entertainment':'🎬',
      'Health':'💊','Bills':'📄','Education':'📚','Salary':'💰',
      'Freelance':'💻','Investment':'📊','Others':'📦',
    };
    return emojis[category] ?? '💳';
  }

  String _weekdayName(int weekday) {
    const names = {1:'Monday',2:'Tuesday',3:'Wednesday',4:'Thursday',5:'Friday',6:'Saturday',7:'Sunday'};
    return names[weekday] ?? 'Weekend';
  }
}