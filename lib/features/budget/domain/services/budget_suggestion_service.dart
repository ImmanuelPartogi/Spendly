import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../domain/entities/budget_entity.dart';

// ── Model ─────────────────────────────────────────────────────────────────────

/// Suggestion hasil analisa 3 bulan terakhir.
class BudgetSuggestion {
  final String category;
  final double avg3Month;
  final double suggested;
  final double? currentBudget;

  const BudgetSuggestion({
    required this.category,
    required this.avg3Month,
    required this.suggested,
    this.currentBudget,
  });

  /// Ada perubahan signifikan (>1000) dari budget saat ini.
  bool get hasChange =>
      currentBudget == null || (suggested - currentBudget!).abs() > 1000;
}

// ── Service ───────────────────────────────────────────────────────────────────

/// Hitung saran budget dari rata-rata 3 bulan + buffer 10%.
class BudgetSuggestionService {
  BudgetSuggestionService._();

  static List<BudgetSuggestion> generate({
    required Map<String, List<double>> monthlySpending,
    required Map<String, double> currentBudgets,
  }) {
    final suggestions = <BudgetSuggestion>[];

    monthlySpending.forEach((category, amounts) {
      if (amounts.isEmpty) return;
      final avg = amounts.fold(0.0, (s, v) => s + v) / amounts.length;
      if (avg < 1000) return; // skip kategori yang sangat kecil
      final suggested = (avg * 1.10); // +10% buffer
      suggestions.add(BudgetSuggestion(
        category: category,
        avg3Month: avg,
        suggested: suggested,
        currentBudget: currentBudgets[category],
      ));
    });

    // Sort by avg spending desc — kategori terbesar tampil dulu
    suggestions.sort((a, b) => b.avg3Month.compareTo(a.avg3Month));
    return suggestions;
  }
}

// ── Smart Budget Suggestion Sheet ─────────────────────────────────────────────

class SmartBudgetSuggestionSheet extends ConsumerStatefulWidget {
  const SmartBudgetSuggestionSheet({super.key});

  @override
  ConsumerState<SmartBudgetSuggestionSheet> createState() =>
      _SmartBudgetSuggestionSheetState();
}

class _SmartBudgetSuggestionSheetState
    extends ConsumerState<SmartBudgetSuggestionSheet> {
  final _applied = <String>{};

  Future<void> _applyAll(List<BudgetSuggestion> suggestions) async {
    for (final s in suggestions) {
      await _applySingle(s);
    }
    await Future.delayed(const Duration(milliseconds: 300));
    if (mounted) Navigator.pop(context);
  }

  Future<void> _applySingle(BudgetSuggestion s) async {
    await ref.read(setBudgetUseCaseProvider).call(
          BudgetEntity(
            category: s.category,
            limitAmount: s.suggested,
          ),
        );
    setState(() => _applied.add(s.category));
  }

  @override
  Widget build(BuildContext context) {
    // Data real dari 3 bulan terakhir
    final spendingAsync = ref.watch(monthlySpendingProvider);
    final budgetsAsync = ref.watch(budgetsWithSpentProvider);

    return Container(
      margin: const EdgeInsets.only(top: 60),
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.auto_awesome_rounded,
                      color: AppColors.primary, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Smart Budget',
                          style: Theme.of(context).textTheme.titleLarge),
                      const Text(
                        'Berdasarkan rata-rata 3 bulan terakhir',
                        style: TextStyle(
                            fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          const Divider(),
          // Body — data dari provider
          Expanded(
            child: spendingAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.bar_chart_rounded,
                        size: 48, color: AppColors.border),
                    const SizedBox(height: 12),
                    const Text('Belum ada data pengeluaran',
                        style: TextStyle(color: AppColors.textSecondary)),
                    const SizedBox(height: 4),
                    Text('Tambah beberapa transaksi dulu',
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textSecondary)),
                  ],
                ),
              ),
              data: (spending) {
                final currentBudgets = {
                  for (final b in budgetsAsync) b.category: b.limitAmount,
                };

                final suggestions = BudgetSuggestionService.generate(
                  monthlySpending: spending,
                  currentBudgets: currentBudgets,
                );

                if (suggestions.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('📊', style: TextStyle(fontSize: 48)),
                        SizedBox(height: 12),
                        Text(
                          'Belum cukup data',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Butuh minimal 1 bulan riwayat transaksi',
                          style: TextStyle(
                              fontSize: 12, color: AppColors.textSecondary),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                return Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: suggestions.length,
                        itemBuilder: (_, i) {
                          final s = suggestions[i];
                          return _SuggestionCard(
                            suggestion: s,
                            isApplied: _applied.contains(s.category),
                            onApply: () => _applySingle(s),
                          );
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _applied.length == suggestions.length
                              ? null
                              : () => _applyAll(suggestions),
                          icon: const Icon(Icons.check_circle_rounded),
                          label: const Text('Terapkan Semua'),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SuggestionCard extends StatelessWidget {
  final BudgetSuggestion suggestion;
  final bool isApplied;
  final VoidCallback onApply;

  const _SuggestionCard({
    required this.suggestion,
    required this.isApplied,
    required this.onApply,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isApplied ? AppColors.income.withOpacity(0.06) : AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color:
              isApplied ? AppColors.income.withOpacity(0.3) : AppColors.border,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  suggestion.category,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  'Rata-rata: ${CurrencyFormatter.formatCompact(suggestion.avg3Month)}',
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 2),
                RichText(
                  text: TextSpan(
                    style: const TextStyle(fontSize: 12),
                    children: [
                      const TextSpan(
                        text: 'Saran budget: ',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                      TextSpan(
                        text: CurrencyFormatter.formatCompact(
                            suggestion.suggested),
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (suggestion.currentBudget != null)
                        TextSpan(
                          text:
                              ' (sekarang: ${CurrencyFormatter.formatCompact(suggestion.currentBudget!)})',
                          style: const TextStyle(
                              color: AppColors.textSecondary, fontSize: 11),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          isApplied
              ? const Icon(Icons.check_circle_rounded, color: AppColors.income)
              : TextButton(
                  onPressed: onApply,
                  child: const Text('Terapkan'),
                ),
        ],
      ),
    );
  }
}
