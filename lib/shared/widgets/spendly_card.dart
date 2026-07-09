import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// SpendlyCard — Universal card component
//
// Upgrades vs v1:
// - Shadow lebih refined: color-matched, multi-layer di mode elevated
// - Press state: scale + subtle brightness shift
// - Gradient border opsional via `borderGradient`
// - `glowColor` untuk hero cards seperti balance card
// - Inner highlight di top edge (light mode) — efek glossy premium
// - RepaintBoundary tetap dipertahankan untuk performa
// ─────────────────────────────────────────────────────────────────────────────

class SpendlyCard extends StatefulWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color? color;
  final VoidCallback? onTap;
  final double? borderRadius;
  final Gradient? gradient;
  final bool showBorder;
  final bool elevated;

  /// Warna glow untuk hero cards — akan diterapkan sebagai colored shadow
  final Color? glowColor;

  const SpendlyCard({
    super.key,
    required this.child,
    this.padding,
    this.color,
    this.onTap,
    this.borderRadius,
    this.gradient,
    this.showBorder = true,
    this.elevated = false,
    this.glowColor,
  });

  @override
  State<SpendlyCard> createState() => _SpendlyCardState();
}

class _SpendlyCardState extends State<SpendlyCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pressCtrl;
  late final Animation<double>   _scaleAnim;
  late final Animation<double>   _opacityAnim;

  @override
  void initState() {
    super.initState();
    _pressCtrl = AnimationController(
      vsync: this,
      duration: kDurationFast,
      reverseDuration: const Duration(milliseconds: 220),
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.972).animate(
      CurvedAnimation(parent: _pressCtrl, curve: Curves.easeOut),
    );
    _opacityAnim = Tween<double>(begin: 1.0, end: 0.88).animate(
      CurvedAnimation(parent: _pressCtrl, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _pressCtrl.dispose();
    super.dispose();
  }

  void _onTapDown(_) {
    if (widget.onTap != null) _pressCtrl.forward();
  }

  void _onTapUp(_) {
    if (widget.onTap != null) _pressCtrl.reverse();
  }

  void _onTapCancel() {
    if (widget.onTap != null) _pressCtrl.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final isDark   = Theme.of(context).brightness == Brightness.dark;
    final radius   = widget.borderRadius ?? 20.0;
    final bgColor  = widget.gradient == null
        ? (widget.color ?? (isDark ? AppColors.cardDark : AppColors.card))
        : null;
    final bdrColor = isDark ? AppColors.borderDark : AppColors.border;

    // ── Shadow strategy ───────────────────────────────────────────────────
    List<BoxShadow>? shadows;

    if (widget.glowColor != null) {
      // Hero card dengan custom glow
      shadows = [
        BoxShadow(
          color: widget.glowColor!.withValues(alpha: isDark ? 0.28 : 0.18),
          blurRadius: 28,
          offset: const Offset(0, 8),
          spreadRadius: -4,
        ),
        BoxShadow(
          color: widget.glowColor!.withValues(alpha: isDark ? 0.10 : 0.07),
          blurRadius: 56,
          offset: const Offset(0, 16),
          spreadRadius: -8,
        ),
      ];
    } else if (widget.elevated) {
      shadows = [
        BoxShadow(
          color: isDark
              ? Colors.black.withValues(alpha: 0.45)
              : AppColors.primary.withValues(alpha: 0.10),
          blurRadius: 24,
          offset: const Offset(0, 8),
          spreadRadius: -2,
        ),
        if (!isDark)
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.04),
            blurRadius: 48,
            offset: const Offset(0, 16),
            spreadRadius: -4,
          ),
      ];
    } else if (!isDark) {
      shadows = [
        BoxShadow(
          color: const Color(0xFF4F6EF7).withValues(alpha: 0.06),
          blurRadius: 14,
          offset: const Offset(0, 4),
          spreadRadius: -2,
        ),
      ];
    }
    // Dark mode: no shadow, border is enough

    return RepaintBoundary(
      child: GestureDetector(
        onTapDown: _onTapDown,
        onTapUp: _onTapUp,
        onTapCancel: _onTapCancel,
        onTap: widget.onTap,
        child: AnimatedBuilder(
          animation: _pressCtrl,
          builder: (_, child) => Transform.scale(
            scale: _scaleAnim.value,
            child: Opacity(
              opacity: _opacityAnim.value,
              child: child,
            ),
          ),
          child: AnimatedContainer(
            duration: kDurationFast,
            curve: kCurveDefault,
            decoration: BoxDecoration(
              color: bgColor,
              gradient: widget.gradient,
              borderRadius: BorderRadius.circular(radius),
              border: (widget.showBorder && widget.gradient == null)
                  ? Border.all(color: bdrColor, width: 1)
                  : null,
              boxShadow: shadows,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(radius),
              child: Stack(
                children: [
                  // Inner top highlight (glossy effect, light mode only)
                  if (!isDark && widget.gradient == null)
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        height: 1,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.white.withValues(alpha: 0),
                              Colors.white.withValues(alpha: 0.8),
                              Colors.white.withValues(alpha: 0),
                            ],
                          ),
                        ),
                      ),
                    ),
                  Padding(
                    padding: widget.padding ?? const EdgeInsets.all(16),
                    child: widget.child,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SpendlyStatCard — Stat card dengan animated counter + trend indicator
//
// Upgrades vs v1:
// - Icon container pakai gradient tint (bukan flat opacity)
// - Trend badge: opsional dengan arah panah (naik/turun)
// - Value counter animation dengan easeOutQuart
// - Typography lebih refined: value besar, label kecil tapi readable
// - Subtle background tint sesuai warna stat
// ─────────────────────────────────────────────────────────────────────────────

class SpendlyStatCard extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  final IconData icon;

  /// Label badge opsional (misal: "Bulan ini", "+12%")
  final String? badge;

  /// Tampilkan trend arrow: true=naik, false=turun, null=tidak tampil
  final bool? trendUp;

  const SpendlyStatCard({
    super.key,
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
    this.badge,
    this.trendUp,
  });

  @override
  Widget build(BuildContext context) {
    final isDark  = Theme.of(context).brightness == Brightness.dark;
    final txtSec  = isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;

    return SpendlyCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Top row: icon + badge ──────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon container with gradient
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      color.withValues(alpha: isDark ? 0.22 : 0.15),
                      color.withValues(alpha: isDark ? 0.10 : 0.07),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: color.withValues(alpha: isDark ? 0.18 : 0.12),
                  ),
                ),
                child: Center(
                  child: Icon(icon, color: color, size: 17),
                ),
              ),

              // Badge or trend indicator
              if (badge != null || trendUp != null)
                _StatBadge(
                  label: badge,
                  trendUp: trendUp,
                  color: color,
                  isDark: isDark,
                ),
            ],
          ),
          const SizedBox(height: 12),

          // ── Animated value ──────────────────────────────────────────────
          TweenAnimationBuilder<double>(
            key: ValueKey(value),
            tween: Tween(begin: 0, end: value),
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeOutQuart,
            builder: (_, val, __) {
              return Text(
                _formatValue(val),
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: color,
                  letterSpacing: -0.5,
                  height: 1.0,
                ),
              );
            },
          ),
          const SizedBox(height: 4),

          // ── Label ───────────────────────────────────────────────────────
          Text(
            label,
            style: TextStyle(
              fontSize: 11.5,
              color: txtSec,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );
  }

  String _formatValue(double val) {
    if (val >= 1000000000) {
      return 'Rp ${(val / 1000000000).toStringAsFixed(1)} M';
    } else if (val >= 1000000) {
      return 'Rp ${(val / 1000000).toStringAsFixed(1)} jt';
    } else if (val >= 1000) {
      return 'Rp ${(val / 1000).toStringAsFixed(0)} rb';
    }
    return 'Rp ${val.toStringAsFixed(0)}';
  }
}

class _StatBadge extends StatelessWidget {
  final String? label;
  final bool? trendUp;
  final Color color;
  final bool isDark;

  const _StatBadge({
    required this.label,
    required this.trendUp,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.14 : 0.09),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withValues(alpha: isDark ? 0.18 : 0.12),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (trendUp != null) ...[
            Icon(
              trendUp!
                  ? Icons.arrow_upward_rounded
                  : Icons.arrow_downward_rounded,
              size: 9,
              color: color,
            ),
            const SizedBox(width: 3),
          ],
          if (label != null)
            Text(
              label!,
              style: TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w700,
                color: color,
                letterSpacing: 0.1,
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SpendlyBalanceCard — Khusus untuk balance/hero card di dashboard
//
// Komponen baru yang belum ada sebelumnya:
// - Full gradient background
// - Large amount dengan animated counter
// - Income/expense mini chips di bawah
// - Dekoratif lingkaran di background
// ─────────────────────────────────────────────────────────────────────────────

class SpendlyBalanceCard extends StatelessWidget {
  final double totalBalance;
  final double monthlyIncome;
  final double monthlyExpense;
  final String? walletName;
  final VoidCallback? onTap;

  const SpendlyBalanceCard({
    super.key,
    required this.totalBalance,
    required this.monthlyIncome,
    required this.monthlyExpense,
    this.walletName,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SpendlyCard(
      gradient: AppColors.primaryGradient,
      borderRadius: 24,
      showBorder: false,
      elevated: true,
      glowColor: AppColors.primary,
      onTap: onTap,
      padding: EdgeInsets.zero,
      child: Stack(
        children: [
          // Decorative circles
          Positioned(
            top: -24,
            right: -24,
            child: Container(
              width: 130,
              height: 130,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.06),
              ),
            ),
          ),
          Positioned(
            bottom: -20,
            left: -20,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.04),
              ),
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Label row
                Row(
                  children: [
                    Text(
                      walletName ?? 'Total Saldo',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.75),
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 9, vertical: 4,),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Aktif',
                        style: TextStyle(
                          fontSize: 10.5,
                          color: Colors.white.withValues(alpha: 0.90),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Balance
                TweenAnimationBuilder<double>(
                  key: ValueKey(totalBalance),
                  tween: Tween(begin: 0, end: totalBalance),
                  duration: const Duration(milliseconds: 900),
                  curve: Curves.easeOutQuart,
                  builder: (_, val, __) {
                    return Text(
                      _formatBalance(val),
                      style: const TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -1.2,
                        height: 1.0,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),

                // Divider
                Container(
                  height: 1,
                  color: Colors.white.withValues(alpha: 0.15),
                ),
                const SizedBox(height: 16),

                // Income + Expense chips
                Row(
                  children: [
                    Expanded(
                      child: _BalanceChip(
                        label: 'Pemasukan',
                        amount: monthlyIncome,
                        icon: Icons.arrow_downward_rounded,
                        color: AppColors.income,
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 36,
                      color: Colors.white.withValues(alpha: 0.15),
                    ),
                    Expanded(
                      child: _BalanceChip(
                        label: 'Pengeluaran',
                        amount: monthlyExpense,
                        icon: Icons.arrow_upward_rounded,
                        color: const Color(0xFFFFB3BF),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatBalance(double val) {
    if (val.abs() >= 1000000000) {
      return 'Rp ${(val / 1000000000).toStringAsFixed(2)} M';
    } else if (val.abs() >= 1000000) {
      return 'Rp ${(val / 1000000).toStringAsFixed(2)} jt';
    } else if (val.abs() >= 1000) {
      return 'Rp ${(val / 1000).toStringAsFixed(0)}.000';
    }
    return 'Rp ${val.toStringAsFixed(0)}';
  }
}

class _BalanceChip extends StatelessWidget {
  final String label;
  final double amount;
  final IconData icon;
  final Color color;

  const _BalanceChip({
    required this.label,
    required this.amount,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Icon(icon, color: color, size: 13),
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 10.5,
                  color: Colors.white.withValues(alpha: 0.65),
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: 1),
              TweenAnimationBuilder<double>(
                key: ValueKey(amount),
                tween: Tween(begin: 0, end: amount),
                duration: const Duration(milliseconds: 900),
                curve: Curves.easeOutQuart,
                builder: (_, val, __) => Text(
                  _fmt(val),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _fmt(double v) {
    if (v >= 1000000) return 'Rp ${(v / 1000000).toStringAsFixed(1)}jt';
    if (v >= 1000) return 'Rp ${(v / 1000).toStringAsFixed(0)}rb';
    return 'Rp ${v.toStringAsFixed(0)}';
  }
}