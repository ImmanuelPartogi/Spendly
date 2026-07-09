import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/section_header.dart';
import '../../../../shared/widgets/spendly_card.dart';
import '../../../../shared/widgets/spendly_shimmer.dart';
import '../../../../shared/widgets/transaction_tile.dart';
import 'add_transaction_screen.dart';
import 'search_screen.dart';
import 'transaction_detail_screen.dart';

const double _kBottomPad = 108.0;

class TransactionsScreen extends ConsumerWidget {
  const TransactionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.backgroundDark : AppColors.background;
    final txtPrim = isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;
    final safeTop = MediaQuery.of(context).padding.top;
    final safeBottom = MediaQuery.of(context).padding.bottom;

    final txAsync = ref.watch(recentTransactionsProvider);

    return Scaffold(
      backgroundColor: bgColor,
      extendBody: true,
      body: txAsync.when(
        loading: () => _buildScroll(
          isDark: isDark,
          safeTop: safeTop,
          context: context,
          sliver: SliverPadding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, _kBottomPad + safeBottom),
            sliver: const SliverToBoxAdapter(
              child: SpendlyCard(
                padding: EdgeInsets.symmetric(vertical: 4),
                child: TransactionListShimmer(count: 6),
              ),
            ),
          ),
        ),
        error: (e, _) => Center(
          child: Text(
            'Terjadi kesalahan: $e',
            style: TextStyle(
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondary,
            ),
          ),
        ),
        data: (txList) {
          if (txList.isEmpty) {
            return _buildScroll(
              isDark: isDark,
              safeTop: safeTop,
              context: context,
              sliver: SliverFillRemaining(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: SpendlyCard(
                      child: EmptyState(
                        icon: Icons.receipt_long_rounded,
                        title: 'Belum ada transaksi',
                        subtitle: 'Tap + untuk mencatat transaksi pertama',
                        actionLabel: 'Tambah Transaksi',
                        onAction: () => _openAdd(context),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }

          return _buildScroll(
            isDark: isDark,
            safeTop: safeTop,
            context: context,
            sliver: SliverPadding(
              padding:
                  EdgeInsets.fromLTRB(16, 8, 16, _kBottomPad + safeBottom),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  SectionHeader(title: 'Semua Transaksi', titleColor: txtPrim),
                  const SizedBox(height: 12),
                  SpendlyCard(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Column(
                      children: txList
                          .asMap()
                          .entries
                          .map((e) => TransactionTile(
                                transaction: e.value,
                                index: e.key,
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => TransactionDetailScreen(
                                        transaction: e.value,),
                                  ),
                                ),
                              ),)
                          .toList(),
                    ),
                  ),
                ]),
              ),
            ),
          );
        },
      ),
      floatingActionButton: Padding(
        padding: EdgeInsets.only(bottom: safeBottom + 10),
        child: GestureDetector(
          onTap: () => _openAdd(context),
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.35),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                  spreadRadius: -4,
                ),
              ],
            ),
            child:
                const Icon(Icons.add_rounded, color: Colors.white, size: 26),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildScroll({
    required bool isDark,
    required double safeTop,
    required BuildContext context,
    required Widget sliver,
  }) {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        _TransactionsAppBar(
          isDark: isDark,
          safeTop: safeTop,
          onSearch: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SearchScreen()),
          ),
        ),
        sliver,
      ],
    );
  }

  void _openAdd(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AddTransactionSheet(),
    );
  }
}

// ─── App Bar ──────────────────────────────────────────────────────────────────

class _TransactionsAppBar extends StatelessWidget {
  final bool isDark;
  final double safeTop;
  final VoidCallback onSearch;

  const _TransactionsAppBar({
    required this.isDark,
    required this.safeTop,
    required this.onSearch,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = isDark ? AppColors.backgroundDark : AppColors.background;
    final txtPrim = isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;
    final txtSec =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;

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
          AnimatedOpacity(
            opacity: isCollapsed ? 0.0 : 1.0,
            duration: const Duration(milliseconds: 150),
            child: Align(
              alignment: Alignment.bottomLeft,
              child: Padding(
                padding: EdgeInsets.fromLTRB(20, safeTop + 12, 60, 14),
                child: OverflowBox(
                  alignment: Alignment.bottomLeft,
                  maxHeight: double.infinity,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Catatan &',
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: txtSec,),),
                      Text('Transaksi',
                          style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              color: txtPrim,
                              letterSpacing: -0.8,
                              height: 1.1,),),
                    ],
                  ),
                ),
              ),
            ),
          ),
          AnimatedOpacity(
            opacity: isCollapsed ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 150),
            child: Align(
              alignment: Alignment.bottomLeft,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 60, 14),
                child: Text('Transaksi',
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: txtPrim,
                        letterSpacing: -0.6,),),
              ),
            ),
          ),
          Positioned(
            right: 16,
            bottom: 10,
            child: GestureDetector(
              onTap: onSearch,
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceDark : AppColors.surface,
                  borderRadius: BorderRadius.circular(11),
                  border: Border.all(
                    color: isDark ? AppColors.borderDark : AppColors.border,
                    width: 0.5,
                  ),
                ),
                child: Icon(Icons.search_rounded, size: 18, color: txtSec),
              ),
            ),
          ),
        ],);
      },),
    );
  }
}