import 'package:easy_localization/easy_localization.dart';
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
      appBar: AppBar(title: Text('Analisis')),
      body: insightsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Terjadi kesalahan: $e')),
        data: (insights) {
          if (insights.isEmpty) {
            return const EmptyState(
              icon: Icons.insights,
              title: 'Belum ada analisis',
              subtitle: 'Tambah transaksi untuk mendapatkan analisis cerdas',
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
                    Text('✨', style: TextStyle(fontSize: 36)),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('smart_analysis'.tr(),
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,),),
                          Text('based_on_month_transactions'.tr(),
                              style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.8),
                                  fontSize: 12,),),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Text('this_month'.tr(), style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              ...insights.map((insight) => Padding(
                    padding: const EdgeInsetsDirectional.only(bottom: 12),
                    child: SpendlyCard(
                      color: insight.isWarning
                          ? AppColors.warning.withValues(alpha: 0.06)
                          : AppColors.card,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: insight.isWarning
                                  ? AppColors.warning.withValues(alpha: 0.12)
                                  : AppColors.primary.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Text(insight.emoji,
                                  style: const TextStyle(fontSize: 22),),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
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
                  ),),
              const SizedBox(height: 80),
            ],
          );
        },
      ),
    );
  }

  String _typeLabel(String type) {
    const map = {
      'category_spend': 'POLA PENGELUARAN',
      'spend_trend': 'TREN BULANAN',
      'highest_day': 'KEBIASAAN',
      'budget_warning': 'PERINGATAN BUDGET',
      'daily_average': 'PROYEKSI',
      'balance_warning': 'ARUS KAS',
      'savings': 'TABUNGAN',
    };
    return map[type] ?? 'ANALISIS';
  }
}
