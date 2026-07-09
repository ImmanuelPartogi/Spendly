import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../domain/entities/budget_entity.dart';
import '../widgets/budget_card.dart';
import '../widgets/budget_summary_card.dart';
import '../widgets/set_budget_sheet.dart';

const double _kBottomPad = 108.0;

class BudgetScreen extends ConsumerWidget {
  const BudgetScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark      = Theme.of(context).brightness == Brightness.dark;
    final bgColor     = isDark ? AppColors.backgroundDark : AppColors.background;
    final txtPrim     = isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;
    final safeTop     = MediaQuery.of(context).padding.top;
    final safeBottom  = MediaQuery.of(context).padding.bottom;

    final budgets       = ref.watch(budgetsWithSpentProvider);
    final totalLimit    = budgets.fold<double>(0, (s, b) => s + b.limitAmount);
    final totalSpent    = budgets.fold<double>(0, (s, b) => s + b.spent);
    final exceededCount = budgets.where((b) => b.isExceeded).length;

    return Scaffold(
      backgroundColor: bgColor,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _BudgetAppBar(
            isDark: isDark,
            safeTop: safeTop,
            onAdd: () => _openSetBudget(context, ref, null),
          ),
          SliverPadding(
            padding: EdgeInsets.fromLTRB(
                16, 4, 16, _kBottomPad + safeBottom,),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                if (budgets.isNotEmpty) ...[
                  BudgetSummaryCard(
                    isDark: isDark,
                    totalLimit: totalLimit,
                    totalSpent: totalSpent,
                    exceededCount: exceededCount,
                    budgetCount: budgets.length,
                  ),
                  const SizedBox(height: 20),
                ],

                if (budgets.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 20),
                    child: EmptyState(
                      title: 'Belum ada anggaran',
                      subtitle:
                          'Tetapkan batas pengeluaran per kategori untuk mulai memantau keuangan',
                      actionLabel: 'Buat Anggaran',
                      onAction: () => _openSetBudget(context, ref, null),
                      icon: Icons.account_balance_wallet_outlined,
                    ),
                  )
                else ...[
                  _BudgetListHeader(
                    isDark: isDark,
                    count: budgets.length,
                    exceededCount: exceededCount,
                    txtPrim: txtPrim,
                  ),
                  const SizedBox(height: 14),
                  ...budgets.map((b) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: BudgetCard(
                          budget: b,
                          isDark: isDark,
                          onEdit: () => _openSetBudget(context, ref, b),
                          onDelete: () async {
                            if (b.id != null) {
                              await ref
                                  .read(deleteBudgetUseCaseProvider)
                                  .call(b.id!);
                            }
                          },
                        ),
                      ),),
                ],
              ]),
            ),
          ),
        ],
      ),
    );
  }

  void _openSetBudget(
      BuildContext ctx, WidgetRef ref, BudgetEntity? existing,) {
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SetBudgetSheet(existing: existing),
    );
  }
}

// ─── App Bar ──────────────────────────────────────────────────────────────────

class _BudgetAppBar extends StatelessWidget {
  final bool isDark;
  final double safeTop;
  final VoidCallback onAdd;

  const _BudgetAppBar({
    required this.isDark,
    required this.safeTop,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = isDark ? AppColors.backgroundDark : AppColors.background;
    final txtPrim = isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;
    final txtSec  = isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;

    return SliverAppBar(
      expandedHeight: 88,
      collapsedHeight: 56,
      pinned: true,
      backgroundColor: bgColor,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      automaticallyImplyLeading: false,
      flexibleSpace: LayoutBuilder(builder: (context, constraints) {
        final isCollapsed = constraints.maxHeight < 72 + safeTop;
        return Stack(clipBehavior: Clip.none, children: [
          // Expanded state
          AnimatedOpacity(
            opacity: isCollapsed ? 0.0 : 1.0,
            duration: const Duration(milliseconds: 150),
            child: Align(
              alignment: Alignment.bottomLeft,
              child: Padding(
                padding:
                    EdgeInsets.fromLTRB(20, safeTop + 12, 60, 14),
                child: OverflowBox(
                  alignment: Alignment.bottomLeft,
                  maxHeight: double.infinity,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Kelola &',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: txtSec,),
                      ),
                      Text(
                        'Anggaran',
                        style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: txtPrim,
                            letterSpacing: -0.8,
                            height: 1.1,),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Collapsed state
          AnimatedOpacity(
            opacity: isCollapsed ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 150),
            child: Align(
              alignment: Alignment.bottomLeft,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 60, 14),
                child: Text(
                  'Anggaran',
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: txtPrim,
                      letterSpacing: -0.6,),
                ),
              ),
            ),
          ),

          // Tombol tambah
          Positioned(
            right: 16,
            bottom: 10,
            child: GestureDetector(
              onTap: onAdd,
              child: Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(11),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.30),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(Icons.add_rounded,
                    color: Colors.white, size: 18,),
              ),
            ),
          ),
        ],);
      },),
    );
  }
}

// ─── Header daftar anggaran ───────────────────────────────────────────────────

class _BudgetListHeader extends StatelessWidget {
  final bool isDark;
  final int count;
  final int exceededCount;
  final Color txtPrim;

  const _BudgetListHeader({
    required this.isDark,
    required this.count,
    required this.exceededCount,
    required this.txtPrim,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          'Anggaran Aktif',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: txtPrim,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: AppColors.primary
                .withValues(alpha: isDark ? 0.18 : 0.10),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '$count',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
        ),
        const Spacer(),
        if (exceededCount > 0)
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(children: [
              const Icon(Icons.warning_amber_rounded,
                  color: AppColors.error, size: 11,),
              const SizedBox(width: 3),
              Text(
                '$exceededCount terlampaui',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.error,
                ),
              ),
            ],),
          ),
      ],
    );
  }
}