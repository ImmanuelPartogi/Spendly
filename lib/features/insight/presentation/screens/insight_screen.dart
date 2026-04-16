import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/spendly_card.dart';

class InsightScreen extends ConsumerWidget {
  const InsightScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final insightsAsync = ref.watch(insightsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Insights')),
      body: insightsAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (insights) {
          if (insights.isEmpty) {
            return const EmptyState(
              icon: Icons.insights,
              title: 'No insights yet',
              subtitle:
                  'Add transactions to get smart analysis',
            );
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Text('✨',
                        style: TextStyle(fontSize: 36)),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          const Text('Smart Insights',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700)),
                          Text(
                              'Based on your transactions this month',
                              style: TextStyle(
                                  color:
                                      Colors.white.withOpacity(0.8),
                                  fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Text('This Month',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              ...insights.map((insight) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: SpendlyCard(
                      color: insight.isWarning
                          ? AppColors.warning.withOpacity(0.06)
                          : AppColors.card,
                      child: Row(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: insight.isWarning
                                  ? AppColors.warning
                                      .withOpacity(0.12)
                                  : AppColors.primary
                                      .withOpacity(0.08),
                              borderRadius:
                                  BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Text(insight.emoji,
                                  style: const TextStyle(
                                      fontSize: 22)),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _typeLabel(insight.type),
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: insight.isWarning
                                        ? AppColors.warning
                                        : AppColors.primary,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  insight.message,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.textPrimary,
                                    height: 1.45,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  )),
              const SizedBox(height: 80),
            ],
          );
        },
      ),
    );
  }

  String _typeLabel(String type) {
    const map = {
      'category_spend': 'SPENDING PATTERN',
      'spend_trend': 'MONTHLY TREND',
      'highest_day': 'BEHAVIOR',
      'budget_warning': 'BUDGET ALERT',
      'daily_average': 'PROJECTION',
      'balance_warning': 'CASHFLOW',
      'savings': 'SAVINGS',
    };
    return map[type] ?? 'INSIGHT';
  }
}