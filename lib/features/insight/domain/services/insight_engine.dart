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

    // Kategori terbesar
    if (categoryTotals.isNotEmpty && totalExpense > 0) {
      final sorted = categoryTotals.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      final top = sorted.first;
      final pct = ((top.value / totalExpense) * 100).round();
      insights.add(InsightData(
        type: 'category_spend',
        emoji: _categoryEmoji(top.key),
        message: '$pct% pengeluaran bulan ini berasal dari kategori ${top.key}',
      ),);
    }

    // Hari dengan pengeluaran tertinggi
    final weekdayTotals = await _txRepo.getWeekdayTotals(year, month, 'expense');
    if (weekdayTotals.values.any((v) => v > 0)) {
      final maxEntry = weekdayTotals.entries
          .reduce((a, b) => a.value > b.value ? a : b);
      insights.add(InsightData(
        type: 'highest_day',
        emoji: '📅',
        message: 'Kamu paling banyak belanja di hari ${_weekdayName(maxEntry.key)} bulan ini',
      ),);
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
          message: 'Pengeluaran naik ${pct.abs().toStringAsFixed(0)}% dibanding bulan lalu',
          isWarning: pct > 20,
        ),);
      } else if (pct < 0) {
        insights.add(InsightData(
          type: 'spend_trend',
          emoji: '📉',
          message: 'Pengeluaran turun ${pct.abs().toStringAsFixed(0)}% dibanding bulan lalu, pertahankan!',
        ),);
      }
    }

    // Peringatan anggaran
    final budgets = await _budgetRepo.getAllBudgets();
    for (final budget in budgets) {
      final spent = categoryTotals[budget.category] ?? 0;
      final pct = budget.limitAmount > 0 ? spent / budget.limitAmount : 0.0;
      if (pct >= 1.0) {
        insights.add(InsightData(
          type: 'budget_warning',
          emoji: '🚨',
          isWarning: true,
          message:
              'Anggaran ${budget.category} sudah terlampaui! '
              '${CurrencyFormatter.formatCompact(spent)} / '
              '${CurrencyFormatter.formatCompact(budget.limitAmount)}',
        ),);
      } else if (pct >= 0.8) {
        insights.add(InsightData(
          type: 'budget_warning',
          emoji: '⚠️',
          isWarning: true,
          message:
              'Anggaran ${budget.category} sudah terpakai 80%. '
              'Sisa ${CurrencyFormatter.formatCompact(budget.limitAmount - spent)}',
        ),);
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
          message: 'Kamu berhasil menabung ${CurrencyFormatter.formatCompact(saved)} bulan ini!',
        ),);
      } else {
        insights.add(InsightData(
          type: 'balance_warning',
          emoji: '💸',
          isWarning: ratio > 1.0,
          message: 'Kamu sudah menggunakan ${(ratio * 100).round()}% dari pemasukan bulan ini',
        ),);
      }
    }

    return insights;
  }

  String _categoryEmoji(String category) {
    const emojis = {
      'Makanan & Minuman': '🍔',
      'Transportasi':      '🚗',
      'Belanja':           '🛍️',
      'Hiburan':           '🎬',
      'Kesehatan':         '💊',
      'Tagihan & Utilitas':'📄',
      'Pendidikan':        '📚',
      'Gaji':              '💰',
      'Freelance':         '💻',
      'Investasi':         '📊',
      'Lainnya':           '📦',
    };
    return emojis[category] ?? '💳';
  }

  String _weekdayName(int weekday) {
    const names = {
      1: 'Senin',
      2: 'Selasa',
      3: 'Rabu',
      4: 'Kamis',
      5: 'Jumat',
      6: 'Sabtu',
      7: 'Minggu',
    };
    return names[weekday] ?? 'Akhir Pekan';
  }
}