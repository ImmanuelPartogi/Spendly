import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Model
// ─────────────────────────────────────────────────────────────────────────────

class BudgetHistoryEntry {
  final String month;        // "Maret 2026"
  final double spent;
  final double budget;
  final bool isOnBudget;
  final Map<String, double> categoryBreakdown; // { 'Food': 320000, ... }

  const BudgetHistoryEntry({
    required this.month,
    required this.spent,
    required this.budget,
    required this.isOnBudget,
    this.categoryBreakdown = const {},
  });

  double get ratio => budget > 0 ? (spent / budget).clamp(0.0, 2.0) : 0;
  double get saved => (budget - spent).clamp(0, double.infinity);
}

// ─────────────────────────────────────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────────────────────────────────────

class BudgetHistoryScreen extends ConsumerWidget {
  const BudgetHistoryScreen({super.key});

  // Demo data — ganti dengan Riverpod provider
  static final _history = [
    const BudgetHistoryEntry(
      month: 'Maret 2026',
      spent: 3200000,
      budget: 3500000,
      isOnBudget: true,
    ),
    const BudgetHistoryEntry(
      month: 'Februari 2026',
      spent: 2900000,
      budget: 3000000,
      isOnBudget: true,
    ),
    const BudgetHistoryEntry(
      month: 'Januari 2026',
      spent: 3600000,
      budget: 3000000,
      isOnBudget: false,
    ),
    const BudgetHistoryEntry(
      month: 'Desember 2025',
      spent: 2750000,
      budget: 3000000,
      isOnBudget: true,
    ),
    const BudgetHistoryEntry(
      month: 'November 2025',
      spent: 2100000,
      budget: 3000000,
      isOnBudget: true,
    ),
    const BudgetHistoryEntry(
      month: 'Oktober 2025',
      spent: 3250000,
      budget: 3000000,
      isOnBudget: false,
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // TODO: ganti _history dengan ref.watch(budgetHistoryProvider)
    final history = _history;

    final exceededCount = history.where((h) => !h.isOnBudget).length;
    final onBudgetCount = history.length - exceededCount;
    final successRate = history.isEmpty
        ? 0
        : (onBudgetCount / history.length * 100).round();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Riwayat Budget')),
      body: Column(
        children: [
          // ── Summary row ─────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              children: [
                Expanded(
                  child: _StatBox(
                    label: 'On Budget',
                    value: '${onBudgetCount}x',
                    color: AppColors.income,
                    icon: Icons.check_circle_rounded,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _StatBox(
                    label: 'Exceeded',
                    value: '${exceededCount}x',
                    color: AppColors.expense,
                    icon: Icons.warning_rounded,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _StatBox(
                    label: 'Success Rate',
                    value: '$successRate%',
                    color: AppColors.primary,
                    icon: Icons.trending_up_rounded,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          const Divider(height: 1),

          // ── History list ────────────────────────────────────────────────
          Expanded(
            child: history.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('📊',
                            style: TextStyle(fontSize: 44)),
                        SizedBox(height: 12),
                        Text(
                          'Belum ada riwayat budget',
                          style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 15),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: history.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: 10),
                    itemBuilder: (_, i) =>
                        _HistoryCard(entry: history[i]),
                  ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Widgets
// ─────────────────────────────────────────────────────────────────────────────

class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _StatBox({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final BudgetHistoryEntry entry;
  const _HistoryCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    final color =
        entry.isOnBudget ? AppColors.income : AppColors.expense;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Month + badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                entry.month,
                style: const TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 14),
              ),
              _StatusBadge(isOnBudget: entry.isOnBudget),
            ],
          ),
          const SizedBox(height: 14),

          // Spent / budget row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Pengeluaran',
                    style: TextStyle(
                        fontSize: 10,
                        color: AppColors.textSecondary),
                  ),
                  Text(
                    CurrencyFormatter.format(entry.spent),
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: color,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    'Budget',
                    style: TextStyle(
                        fontSize: 10,
                        color: AppColors.textSecondary),
                  ),
                  Text(
                    CurrencyFormatter.format(entry.budget),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: entry.ratio.clamp(0.0, 1.0),
              backgroundColor: color.withOpacity(0.1),
              valueColor: AlwaysStoppedAnimation(color),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 6),

          // Sisa / over
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${(entry.ratio * 100).toStringAsFixed(0)}% digunakan',
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: color),
              ),
              Text(
                entry.isOnBudget
                    ? 'Hemat ${CurrencyFormatter.formatCompact(entry.saved)}'
                    : 'Lebih ${CurrencyFormatter.formatCompact(entry.spent - entry.budget)}',
                style: TextStyle(
                    fontSize: 11, color: color),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final bool isOnBudget;
  const _StatusBadge({required this.isOnBudget});

  @override
  Widget build(BuildContext context) {
    final color =
        isOnBudget ? AppColors.income : AppColors.expense;
    final label = isOnBudget ? 'On Budget' : 'Exceeded';
    final icon = isOnBudget
        ? Icons.check_circle_rounded
        : Icons.warning_rounded;

    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}