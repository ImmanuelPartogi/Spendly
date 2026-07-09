import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/insight_card.dart';
import '../../../profile/presentation/screens/profile_screen.dart';
import '../../../transactions/presentation/screens/add_transaction_screen.dart';
import '../../../../core/providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/haptic_utils.dart';
import '../../../../shared/widgets/spendly_motion.dart';
import '../../../../shared/widgets/spendly_shimmer.dart';
import '../../../../shared/widgets/transaction_tile.dart';
import '../widgets/balance_card.dart';
import '../widgets/mini_expense_chart.dart';

/// Dashboard screen with balance card, insights, spending chart,
/// budget overview, and recent transactions.
class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  final _scrollCtrl = ScrollController();
  bool _headerCollapsed = false;
  double _lastOffset = 0;

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(() {
      final current = _scrollCtrl.offset;
      final scrollingDown = current > _lastOffset;

      if (current > 60 && scrollingDown && !_headerCollapsed) {
        setState(() => _headerCollapsed = true);
      } else if (!scrollingDown && _headerCollapsed) {
        setState(() => _headerCollapsed = false);
      }

      if (current <= 10 && _headerCollapsed) {
        setState(() => _headerCollapsed = false);
      }

      _lastOffset = current;
    });
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    await HapticUtils.light();
    ref.invalidate(walletListProvider);
    ref.invalidate(monthlyTransactionsProvider);
    ref.invalidate(insightsProvider);
    await Future.delayed(const Duration(milliseconds: 600));
  }

  void _openAddSheet() {
    HapticUtils.medium();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AddTransactionSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.backgroundDark : AppColors.background;
    final top = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: bgColor,
      extendBodyBehindAppBar: true,
      body: RefreshIndicator(
        onRefresh: _refresh,
        color: AppColors.primary,
        backgroundColor: isDark ? AppColors.cardDark : AppColors.card,
        strokeWidth: 2,
        child: CustomScrollView(
          controller: _scrollCtrl,
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          slivers: [
            SliverPersistentHeader(
              pinned: true,
              delegate: _StickyHeaderDelegate(
                height: top + 68,
                child: _DashboardHeader(
                  isCollapsed: _headerCollapsed,
                  isDark: isDark,
                  topPadding: top,
                ),
              ),
            ),

            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
              sliver: SliverToBoxAdapter(
                child: SpendlyStaggeredItem(
                  index: 0,
                  child: const BalanceCard(),
                ),
              ),
            ),

            SliverPadding(
              padding: const EdgeInsets.only(top: 20),
              sliver: SliverToBoxAdapter(
                child: SpendlyStaggeredItem(
                  index: 1,
                  child: const InsightCarousel(),
                ),
              ),
            ),

            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
              sliver: SliverToBoxAdapter(
                child: SpendlyStaggeredItem(
                  index: 2,
                  child: _SpendingChartCard(isDark: isDark),
                ),
              ),
            ),

            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              sliver: SliverToBoxAdapter(
                child: SpendlyStaggeredItem(
                  index: 3,
                  child: _BudgetOverviewCard(isDark: isDark),
                ),
              ),
            ),

            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
              sliver: SliverToBoxAdapter(
                child: _SectionHeader(
                  label: 'Transaksi Terbaru',
                  isDark: isDark,
                  onSeeAll: () {
                    ref.read(bottomNavIndexProvider.notifier).state = 1;
                  },
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 10)),
            _RecentTransactionsList(isDark: isDark),

            SliverToBoxAdapter(
              child: SizedBox(
                height: _listBottomPad + MediaQuery.of(context).padding.bottom,
              ),
            ),
          ],
        ),
      ),

      floatingActionButton: Padding(
        padding: EdgeInsets.only(
          bottom: _fabBottomOffset + MediaQuery.of(context).padding.bottom,
        ),
        child: _SpendlyFAB(onTap: _openAddSheet),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}

// ─── Dashboard header ─────────────────────────────────────────────────────────

class _DashboardHeader extends ConsumerWidget {
  final bool isCollapsed;
  final bool isDark;
  final double topPadding;

  const _DashboardHeader({
    required this.isCollapsed,
    required this.isDark,
    required this.topPadding,
  });

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Selamat Pagi';
    if (hour < 17) return 'Selamat Siang';
    return 'Selamat Malam';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userName = ref.watch(profileProvider).name;
    final isLoading = userName.isEmpty;
    final textPrimary =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;
    final textSec =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      color: isDark ? AppColors.backgroundDark : AppColors.background,
      padding: EdgeInsets.fromLTRB(
        20,
        topPadding + 10,
        20,
        isCollapsed ? 8 : 10,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const _AvatarButton(),
          const SizedBox(width: 12),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: (isCollapsed || isLoading)
                  ? Align(
                      key: const ValueKey('title'),
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Spendly',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: textPrimary,
                          letterSpacing: -0.3,
                        ),
                      ),
                    )
                  : Align(
                      key: const ValueKey('greeting'),
                      alignment: Alignment.centerLeft,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _greeting,
                            style: TextStyle(fontSize: 13, color: textSec),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            userName,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: textPrimary,
                              letterSpacing: -0.6,
                              height: 1.1,
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AvatarButton extends StatelessWidget {
  const _AvatarButton();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Center(
        child: Text(
          'S',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

// ─── Spending chart card ──────────────────────────────────────────────────────

class _SpendingChartCard extends ConsumerWidget {
  final bool isDark;
  const _SpendingChartCard({required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(monthlyExpenseProvider);

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.border,
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pengeluaran Harian',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimary,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Minggu ini',
                    style: TextStyle(
                      fontSize: 11,
                      color:
                          isDark ? AppColors.textHintDark : AppColors.textHint,
                    ),
                  ),
                ],
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.expense.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _ExpenseDot(),
                    SizedBox(width: 5),
                    Text(
                      'Bulan ini',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AppColors.expense,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const MiniExpenseChart(),
        ],
      ),
    );
  }
}

class _ExpenseDot extends StatelessWidget {
  const _ExpenseDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 5,
      height: 5,
      decoration: const BoxDecoration(
        color: AppColors.expense,
        shape: BoxShape.circle,
      ),
    );
  }
}

// ─── Budget overview card ─────────────────────────────────────────────────────

class _BudgetOverviewCard extends ConsumerWidget {
  final bool isDark;
  const _BudgetOverviewCard({required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final budgets = ref.watch(budgetsWithSpentProvider);

    if (budgets.isEmpty) return const SizedBox.shrink();

    final shown = budgets.take(3).toList();

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.border,
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            label: 'Anggaran',
            isDark: isDark,
            count: budgets.length,
            onSeeAll: () {
              ref.read(bottomNavIndexProvider.notifier).state = 2;
            },
            compact: true,
          ),
          const SizedBox(height: 14),
          ...shown.asMap().entries.map((e) {
            final b = e.value;
            final pct = b.percentage;
            final barColor = b.isExceeded
                ? AppColors.expense
                : b.isWarning
                    ? AppColors.warning
                    : AppColors.primary;

            return Padding(
              padding:
                  EdgeInsets.only(bottom: e.key < shown.length - 1 ? 14 : 0),
              child: _BudgetProgressRow(
                category: b.category,
                spent: b.spent,
                limit: b.limitAmount,
                pct: pct,
                barColor: barColor,
                isDark: isDark,
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _BudgetProgressRow extends StatelessWidget {
  final String category;
  final double spent;
  final double limit;
  final double pct;
  final Color barColor;
  final bool isDark;

  const _BudgetProgressRow({
    required this.category,
    required this.spent,
    required this.limit,
    required this.pct,
    required this.barColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              category,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color:
                    isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
              ),
            ),
            Text(
              '${(pct * 100).toStringAsFixed(0)}%',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: barColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: Stack(
            children: [
              Container(
                height: 5,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceDark : AppColors.surface,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: pct),
                duration: const Duration(milliseconds: 800),
                curve: Curves.easeOutQuart,
                builder: (_, val, __) => FractionallySizedBox(
                  widthFactor: val.clamp(0.01, 1.0),
                  child: Container(
                    height: 5,
                    decoration: BoxDecoration(
                      color: barColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Recent transactions ──────────────────────────────────────────────────────

class _RecentTransactionsList extends ConsumerWidget {
  final bool isDark;
  const _RecentTransactionsList({required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final txAsync = ref.watch(recentTransactionsProvider);

    return txAsync.when(
      loading: () => SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: isDark ? AppColors.cardDark : AppColors.card,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark ? AppColors.borderDark : AppColors.border,
                width: 0.5,
              ),
            ),
            child: const TransactionListShimmer(count: 4),
          ),
        ),
      ),
      error: (_, __) => const SliverToBoxAdapter(child: SizedBox.shrink()),
      data: (txs) {
        if (txs.isEmpty) {
          return SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _EmptyTransactions(isDark: isDark),
            ),
          );
        }

        final displayTxs = txs.take(6).toList();

        return SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverToBoxAdapter(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: isDark ? AppColors.cardDark : AppColors.card,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark ? AppColors.borderDark : AppColors.border,
                  width: 0.5,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Column(
                  children: displayTxs.asMap().entries.map((e) {
                    final tx = e.value;
                    final isLast = e.key == displayTxs.length - 1;
                    return Column(
                      children: [
                        TransactionTile(
                          transaction: tx,
                          index: e.key,
                        ),
                        if (!isLast)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Divider(
                              height: 1,
                              thickness: 0.5,
                              color: isDark
                                  ? AppColors.dividerDark
                                  : AppColors.divider,
                            ),
                          ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _EmptyTransactions extends StatelessWidget {
  final bool isDark;
  const _EmptyTransactions({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.border,
          width: 0.5,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.receipt_long_rounded,
                color: AppColors.primary,
                size: 22,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Belum ada transaksi',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color:
                    isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Tap + untuk mencatat pengeluaran pertama',
              style: TextStyle(
                fontSize: 11.5,
                color: isDark ? AppColors.textHintDark : AppColors.textHint,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Section header ───────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String label;
  final bool isDark;
  final int? count;
  final VoidCallback? onSeeAll;
  final bool compact;

  const _SectionHeader({
    required this.label,
    required this.isDark,
    this.count,
    this.onSeeAll,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: compact ? 13 : 15,
            fontWeight: FontWeight.w700,
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
            letterSpacing: -0.2,
          ),
        ),
        if (count != null) ...[
          const SizedBox(width: 7),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '$count',
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
        const Spacer(),
        if (onSeeAll != null)
          GestureDetector(
            onTap: onSeeAll,
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Lihat Semua',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
                SizedBox(width: 2),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 10,
                  color: AppColors.primary,
                ),
              ],
            ),
          ),
      ],
    );
  }
}

// ─── FAB ──────────────────────────────────────────────────────────────────────
const double _navBarTotalHeight = 10.0;
const double _fabBottomOffset = _navBarTotalHeight;
const double _listBottomPad = _navBarTotalHeight + 32.0;

class _SpendlyFAB extends StatefulWidget {
  final VoidCallback onTap;
  const _SpendlyFAB({required this.onTap});

  @override
  State<_SpendlyFAB> createState() => _SpendlyFABState();
}

class _SpendlyFABState extends State<_SpendlyFAB>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.92).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) {
        _ctrl.reverse();
        widget.onTap();
      },
      onTapCancel: () => _ctrl.reverse(),
      child: AnimatedBuilder(
        animation: _scale,
        builder: (_, child) => Transform.scale(
          scale: _scale.value,
          child: child,
        ),
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
          child: const Icon(
            Icons.add_rounded,
            color: Colors.white,
            size: 26,
          ),
        ),
      ),
    );
  }
}

class _StickyHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  final double height;

  const _StickyHeaderDelegate({required this.child, required this.height});

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return child;
  }

  @override
  bool shouldRebuild(_StickyHeaderDelegate oldDelegate) => true;
}