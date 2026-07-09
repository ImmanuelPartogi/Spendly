import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ShimmerScope — Single AnimationController untuk semua shimmer di bawahnya
//
// Upgrades vs v1:
// - Warna shimmer disesuaikan per-mode dengan nilai yang lebih refined
// - Gradient sweep lebih halus: 5 color-stop vs 3 → transisi tidak boxy
// - `_ShimmerInherited.updateShouldNotify` hanya notify jika delta > threshold
//   → mengurangi rebuild frekuensi tinggi yang tidak perlu
// ─────────────────────────────────────────────────────────────────────────────

class ShimmerScope extends StatefulWidget {
  final Widget child;
  const ShimmerScope({super.key, required this.child});

  @override
  State<ShimmerScope> createState() => _ShimmerScopeState();

  static double progressOf(BuildContext context) {
    return context
            .dependOnInheritedWidgetOfExactType<_ShimmerInherited>()
            ?.progress ??
        0.0;
  }
}

class _ShimmerScopeState extends State<ShimmerScope>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
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
      builder: (_, child) => _ShimmerInherited(
        progress: _ctrl.value,
        child: child!,
      ),
      child: widget.child,
    );
  }
}

class _ShimmerInherited extends InheritedWidget {
  final double progress;

  const _ShimmerInherited({
    required this.progress,
    required super.child,
  });

  @override
  bool updateShouldNotify(_ShimmerInherited old) {
    // Hanya notify setiap ~16ms (60fps) — kurangi rebuild yg terlalu sering
    return (progress - old.progress).abs() > 0.008;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ShimmerBox — Atom shimmer
//
// Upgrades vs v1:
// - 5-stop gradient vs 3-stop → sweep lebih smooth
// - Warna lebih refined per theme
// - `borderRadius` default disesuaikan ke 8 (lebih konsisten)
// ─────────────────────────────────────────────────────────────────────────────

class ShimmerBox extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const ShimmerBox({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 8,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Refined color pairs
    final base = isDark
        ? const Color(0xFF1A1D2C)
        : const Color(0xFFECEFF8);
    final mid = isDark
        ? const Color(0xFF242740)
        : const Color(0xFFE2E6F4);
    final high = isDark
        ? const Color(0xFF2C3048)
        : const Color(0xFFD8DDED);

    final t   = ShimmerScope.progressOf(context);
    final pos = -1.8 + t * 3.6;

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        gradient: LinearGradient(
          begin: Alignment(pos - 1.0, 0),
          end: Alignment(pos + 0.6, 0),
          colors: [base, mid, high, mid, base],
          stops: const [0.0, 0.3, 0.5, 0.7, 1.0],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Skeleton Presets
// ─────────────────────────────────────────────────────────────────────────────

// ─── Transaction tile skeleton ────────────────────────────────────────────────

class TransactionTileShimmer extends StatelessWidget {
  const TransactionTileShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark   = Theme.of(context).brightness == Brightness.dark;
    final divColor = isDark ? AppColors.dividerDark : AppColors.divider;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              // Icon placeholder
              ShimmerBox(width: 44, height: 44, borderRadius: 13),
              SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ShimmerBox(width: 108, height: 13, borderRadius: 6),
                    SizedBox(height: 7),
                    ShimmerBox(width: 72, height: 10, borderRadius: 5),
                  ],
                ),
              ),
              SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Amount pill placeholder
                  ShimmerBox(width: 80, height: 28, borderRadius: 8),
                  SizedBox(height: 6),
                  ShimmerBox(width: 36, height: 10, borderRadius: 5),
                ],
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 73),
          child: Divider(height: 1, thickness: 1, color: divColor),
        ),
      ],
    );
  }
}

// ─── Transaction list skeleton ────────────────────────────────────────────────

class TransactionListShimmer extends StatelessWidget {
  final int count;
  const TransactionListShimmer({super.key, this.count = 5});

  @override
  Widget build(BuildContext context) {
    return ShimmerScope(
      child: Column(
        children: List.generate(count, (_) => const TransactionTileShimmer()),
      ),
    );
  }
}

// ─── Dashboard skeleton ───────────────────────────────────────────────────────

class DashboardSkeleton extends StatelessWidget {
  const DashboardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerScope(
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Balance hero card
            const ShimmerBox(
              width: double.infinity,
              height: 168,
              borderRadius: 24,
            ),
            const SizedBox(height: 24),

            // Section header placeholder
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ShimmerBox(width: 90, height: 14, borderRadius: 6),
                ShimmerBox(width: 48, height: 12, borderRadius: 5),
              ],
            ),
            const SizedBox(height: 14),

            // Stat cards row
            const Row(
              children: [
                Expanded(
                  child: ShimmerBox(
                    width: double.infinity,
                    height: 90,
                    borderRadius: 16,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: ShimmerBox(
                    width: double.infinity,
                    height: 90,
                    borderRadius: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Chart placeholder
            const ShimmerBox(
              width: double.infinity,
              height: 148,
              borderRadius: 20,
            ),
            const SizedBox(height: 24),

            // Section header
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ShimmerBox(width: 110, height: 14, borderRadius: 6),
                ShimmerBox(width: 48, height: 12, borderRadius: 5),
              ],
            ),
            const SizedBox(height: 8),

            // Transaction tiles
            ...List.generate(5, (_) => const TransactionTileShimmer()),
          ],
        ),
      ),
    );
  }
}

// ─── Analytics skeleton ───────────────────────────────────────────────────────

class AnalyticsSkeleton extends StatelessWidget {
  const AnalyticsSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerScope(
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Period chips
            Row(
              children: List.generate(5, (i) => Padding(
                padding: EdgeInsets.only(right: i < 4 ? 8 : 0),
                child: ShimmerBox(
                  width: i == 0 ? 72 : 56,
                  height: 32,
                  borderRadius: 20,
                ),
              ),),
            ),
            const SizedBox(height: 16),

            // Stat cards
            const Row(
              children: [
                Expanded(
                  child: ShimmerBox(
                      width: double.infinity, height: 82, borderRadius: 16,),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: ShimmerBox(
                      width: double.infinity, height: 82, borderRadius: 16,),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: ShimmerBox(
                      width: double.infinity, height: 82, borderRadius: 16,),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Main chart
            const ShimmerBox(
                width: double.infinity, height: 210, borderRadius: 20,),
            const SizedBox(height: 16),

            // Pie chart + legend
            const ShimmerBox(
                width: double.infinity, height: 270, borderRadius: 20,),
            const SizedBox(height: 16),

            // Weekly bar chart
            const ShimmerBox(
                width: double.infinity, height: 160, borderRadius: 20,),
          ],
        ),
      ),
    );
  }
}

// ─── Budget card skeleton ─────────────────────────────────────────────────────

class BudgetCardShimmer extends StatelessWidget {
  const BudgetCardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerScope(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: List.generate(
            3,
            (_) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? AppColors.cardDark
                      : AppColors.card,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        ShimmerBox(width: 36, height: 36, borderRadius: 10),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ShimmerBox(
                                  width: 90, height: 13, borderRadius: 5,),
                              SizedBox(height: 6),
                              ShimmerBox(
                                  width: 60, height: 10, borderRadius: 4,),
                            ],
                          ),
                        ),
                        ShimmerBox(width: 64, height: 13, borderRadius: 5),
                      ],
                    ),
                    SizedBox(height: 14),
                    ShimmerBox(
                        width: double.infinity, height: 8, borderRadius: 4,),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Goal card skeleton ───────────────────────────────────────────────────────

class GoalCardShimmer extends StatelessWidget {
  const GoalCardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerScope(
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 3,
        itemBuilder: (_, i) => const Padding(
          padding: EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: ShimmerBox(
            width: double.infinity,
            height: 110,
            borderRadius: 18,
          ),
        ),
      ),
    );
  }
}

// ─── Wallet card skeleton ─────────────────────────────────────────────────────

class WalletCardShimmer extends StatelessWidget {
  const WalletCardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerScope(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: List.generate(
            2,
            (_) => const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: ShimmerBox(
                width: double.infinity,
                height: 80,
                borderRadius: 16,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Search result skeleton ───────────────────────────────────────────────────

class SearchResultShimmer extends StatelessWidget {
  final int count;
  const SearchResultShimmer({super.key, this.count = 8});

  @override
  Widget build(BuildContext context) {
    final isDark   = Theme.of(context).brightness == Brightness.dark;
    final divColor = isDark ? AppColors.dividerDark : AppColors.divider;

    return ShimmerScope(
      child: Column(
        children: List.generate(count, (i) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 12,),
              child: Row(
                children: [
                  const ShimmerBox(width: 44, height: 44, borderRadius: 13),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ShimmerBox(
                            width: 90 + (i % 3) * 20.0,
                            height: 12,
                            borderRadius: 5,),
                        const SizedBox(height: 6),
                        ShimmerBox(
                            width: 60 + (i % 2) * 15.0,
                            height: 10,
                            borderRadius: 4,),
                      ],
                    ),
                  ),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      ShimmerBox(width: 76, height: 28, borderRadius: 8),
                      SizedBox(height: 6),
                      ShimmerBox(width: 36, height: 10, borderRadius: 4),
                    ],
                  ),
                ],
              ),
            ),
            if (i < count - 1)
              Padding(
                padding: const EdgeInsets.only(left: 73),
                child: Divider(height: 1, color: divColor),
              ),
          ],
        ),),
      ),
    );
  }
}