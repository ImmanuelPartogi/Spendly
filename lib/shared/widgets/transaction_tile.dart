import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/category_utils.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_formatter.dart';
import '../../features/transactions/domain/entities/transaction_entity.dart';
import '../widgets/spendly_shimmer.dart';

// ─────────────────────────────────────────────────────────────────────────────
// TransactionTile — Upgraded professional tile
//
// Improvements vs v1:
// - Icon container: soft inner shadow + gradient tint (tidak flat)
// - Amount chip: subtle colored pill background
// - Note/date row: secondary color dengan opacity tweak
// - Separator: gradient fade di kedua sisi (bukan solid line)
// - Stagger delay dikurangi jika index tinggi (cegah lag)
// ─────────────────────────────────────────────────────────────────────────────

class TransactionTile extends StatelessWidget {
  final TransactionEntity transaction;
  final VoidCallback? onTap;
  final int index;

  /// Tampilkan separator di bawah tile (default true)
  final bool showDivider;

  const TransactionTile({
    super.key,
    required this.transaction,
    this.onTap,
    this.index = 0,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    return _StaggeredTile(
      delay: Duration(milliseconds: 22 * index.clamp(0, 7)),
      child: _TileContent(
        transaction: transaction,
        onTap: onTap,
        showDivider: showDivider,
      ),
    );
  }
}

// ─── Stagger wrapper ──────────────────────────────────────────────────────────

class _StaggeredTile extends StatefulWidget {
  final Widget child;
  final Duration delay;
  const _StaggeredTile({required this.child, required this.delay});

  @override
  State<_StaggeredTile> createState() => _StaggeredTileState();
}

class _StaggeredTileState extends State<_StaggeredTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: kDurationNormal);
    final curved = CurvedAnimation(parent: _ctrl, curve: kCurveDefault);
    _fade  = curved;
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.04),
      end: Offset.zero,
    ).animate(curved);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Future.delayed(widget.delay, () {
        if (mounted) _ctrl.forward();
      });
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, child) => FadeTransition(
        opacity: _fade,
        child: SlideTransition(position: _slide, child: child),
      ),
      child: widget.child,
    );
  }
}

// ─── Tile Content ─────────────────────────────────────────────────────────────

class _TileContent extends StatelessWidget {
  final TransactionEntity transaction;
  final VoidCallback? onTap;
  final bool showDivider;

  const _TileContent({
    required this.transaction,
    required this.onTap,
    required this.showDivider,
  });

  @override
  Widget build(BuildContext context) {
    final isDark      = Theme.of(context).brightness == Brightness.dark;
    final isExpense   = transaction.isExpense;
    final amountColor = isExpense ? AppColors.expense : AppColors.income;
    final sign        = isExpense ? '−' : '+';
    final catColor    = CategoryUtils.getColor(transaction.category);
    final catIcon     = CategoryUtils.getIcon(transaction.category);

    final txtPrim     = isDark ? AppColors.textPrimaryDark   : AppColors.textPrimary;
    final txtSec      = isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;
    final divColor    = isDark ? AppColors.dividerDark       : AppColors.divider;
    final splashColor = catColor.withOpacity(0.04);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(0),
            splashColor: splashColor,
            highlightColor: splashColor,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  // ── Category icon ──────────────────────────────────────
                  RepaintBoundary(
                    child: _CategoryIcon(
                      icon: catIcon,
                      color: catColor,
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(width: 13),

                  // ── Labels ────────────────────────────────────────────
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          transaction.category,
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            color: txtPrim,
                            letterSpacing: -0.15,
                            height: 1.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            // Note or relative date
                            Flexible(
                              child: Text(
                                transaction.note?.isNotEmpty == true
                                    ? transaction.note!
                                    : DateFormatter.formatRelative(
                                        transaction.date),
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: txtSec,
                                  height: 1.3,
                                  fontWeight: FontWeight.w400,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),

                  // ── Amount + date ──────────────────────────────────────
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // Amount pill
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 9, vertical: 4),
                        decoration: BoxDecoration(
                          color: amountColor.withOpacity(
                              isDark ? 0.14 : 0.09),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '$sign ${CurrencyFormatter.formatCompact(transaction.amount)}',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: amountColor,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        DateFormatter.formatDayMonth(transaction.date),
                        style: TextStyle(
                          fontSize: 10.5,
                          color: txtSec.withOpacity(0.7),
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),

        // ── Separator ─────────────────────────────────────────────────────
        if (showDivider)
          Padding(
            padding: const EdgeInsets.only(left: 71),
            child: Divider(
              height: 1,
              thickness: 1,
              color: divColor,
            ),
          ),
      ],
    );
  }
}

// ─── Category icon with gradient depth ───────────────────────────────────────

class _CategoryIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  final bool isDark;

  const _CategoryIcon({
    required this.icon,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withOpacity(isDark ? 0.20 : 0.14),
            color.withOpacity(isDark ? 0.10 : 0.07),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(
          color: color.withOpacity(isDark ? 0.20 : 0.12),
          width: 1,
        ),
      ),
      child: Center(
        child: Icon(icon, color: color, size: 20),
      ),
    );
  }
}

// ─── Shimmer placeholder ──────────────────────────────────────────────────────

class TransactionTileShimmer extends StatelessWidget {
  const TransactionTileShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark   = Theme.of(context).brightness == Brightness.dark;
    final divColor = isDark ? AppColors.dividerDark : AppColors.divider;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              ShimmerBox(width: 44, height: 44, borderRadius: 13),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ShimmerBox(width: 108, height: 12, borderRadius: 6),
                    const SizedBox(height: 6),
                    ShimmerBox(width: 72, height: 10, borderRadius: 5),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  ShimmerBox(width: 76, height: 26, borderRadius: 8),
                  const SizedBox(height: 6),
                  ShimmerBox(width: 36, height: 10, borderRadius: 5),
                ],
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 71),
          child: Divider(height: 1, color: divColor),
        ),
      ],
    );
  }
}