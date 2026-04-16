import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_formatter.dart';

// ─────────────────────────────────────────────────────────────────────────────
// BalanceCard — Redesigned hero card
//
// Perubahan dari versi lama:
// - Savings rate indicator bar (income vs expense ratio)
// - Layout stat item lebih rapi: icon menyatu dengan label
// - Hapus CustomPaint circles → diganti subtle grid pattern
// - Net savings row baru di bawah income/expense
// - Typography lebih kuat: balance lebih besar, label lebih kecil & spaced
// ─────────────────────────────────────────────────────────────────────────────

class BalanceCard extends ConsumerWidget {
  const BalanceCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final balance = ref.watch(totalBalanceProvider);
    final income  = ref.watch(monthlyIncomeProvider);
    final expense = ref.watch(monthlyExpenseProvider);
    final now     = DateTime.now();

    final walletsLoading = ref.watch(walletListProvider).isLoading;
    final txLoading      = ref.watch(monthlyTransactionsProvider).isLoading;

    final net          = income - expense;
    final savingsRate  = income > 0 ? ((net / income).clamp(0.0, 1.0)) : 0.0;
    final isDeficit    = net < 0;

    return RepaintBoundary(
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.28),
              blurRadius: 32,
              offset: const Offset(0, 14),
              spreadRadius: -6,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: Stack(
            children: [
              // ── Subtle dot-grid overlay ─────────────────────────────────
              Positioned.fill(
                child: CustomPaint(painter: _DotGridPainter()),
              ),

              Padding(
                padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Top row: label + month badge ──────────────────────
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'TOTAL BALANCE',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.60),
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.4,
                              ),
                            ),
                            const SizedBox(height: 6),
                            walletsLoading
                                ? const _Skeleton(width: 150, height: 36)
                                : _AnimatedBalance(value: balance),
                          ],
                        ),
                        _MonthBadge(label: DateFormatter.formatMonthYear(now)),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // ── Savings rate bar ──────────────────────────────────
                    if (!txLoading)
                      _SavingsBar(
                        rate: savingsRate,
                        isDeficit: isDeficit,
                      ),

                    const SizedBox(height: 20),

                    // ── Divider ───────────────────────────────────────────
                    Container(
                      height: 0.5,
                      color: Colors.white.withOpacity(0.15),
                    ),
                    const SizedBox(height: 18),

                    // ── Income / Expense / Net row ────────────────────────
                    Row(
                      children: [
                        Expanded(
                          child: _StatPill(
                            label: 'Income',
                            icon: Icons.south_rounded,
                            value: income,
                            isLoading: txLoading,
                            color: AppColors.accentTeal,
                          ),
                        ),
                        _VerticalDivider(),
                        Expanded(
                          child: _StatPill(
                            label: 'Expense',
                            icon: Icons.north_rounded,
                            value: expense,
                            isLoading: txLoading,
                            color: AppColors.expense,
                          ),
                        ),
                        _VerticalDivider(),
                        Expanded(
                          child: _StatPill(
                            label: 'Net',
                            icon: isDeficit
                                ? Icons.trending_down_rounded
                                : Icons.trending_up_rounded,
                            value: net.abs(),
                            isLoading: txLoading,
                            color: isDeficit
                                ? AppColors.expense
                                : AppColors.accentTeal,
                            prefix: isDeficit ? '−' : '+',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Dot grid CustomPainter ───────────────────────────────────────────────────

class _DotGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.05)
      ..style = PaintingStyle.fill;

    const spacing = 18.0;
    const radius  = 1.2;

    for (double x = spacing; x < size.width; x += spacing) {
      for (double y = spacing; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), radius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DotGridPainter old) => false;
}

// ─── Month badge ──────────────────────────────────────────────────────────────

class _MonthBadge extends StatelessWidget {
  final String label;
  const _MonthBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

// ─── Animated balance ─────────────────────────────────────────────────────────

class _AnimatedBalance extends StatelessWidget {
  final double value;
  const _AnimatedBalance({required this.value});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      key: ValueKey(value),
      tween: Tween(begin: 0, end: value),
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOutQuart,
      builder: (_, val, __) => Text(
        CurrencyFormatter.format(val),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 32,
          fontWeight: FontWeight.w800,
          letterSpacing: -1.2,
          height: 1.0,
        ),
      ),
    );
  }
}

// ─── Savings rate bar ─────────────────────────────────────────────────────────

class _SavingsBar extends StatelessWidget {
  final double rate;
  final bool isDeficit;
  const _SavingsBar({required this.rate, required this.isDeficit});

  @override
  Widget build(BuildContext context) {
    final barColor = isDeficit ? AppColors.expense : AppColors.accentTeal;
    final pct = (rate * 100).toStringAsFixed(0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              isDeficit ? 'Deficit bulan ini' : 'Tingkat tabungan',
              style: TextStyle(
                color: Colors.white.withOpacity(0.60),
                fontSize: 10.5,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.2,
              ),
            ),
            Text(
              isDeficit ? '−$pct%' : '$pct%',
              style: TextStyle(
                color: barColor,
                fontSize: 11,
                fontWeight: FontWeight.w700,
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
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: rate),
                duration: const Duration(milliseconds: 900),
                curve: Curves.easeOutQuart,
                builder: (_, val, __) => FractionallySizedBox(
                  widthFactor: val.clamp(0.02, 1.0),
                  child: Container(
                    height: 4,
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

// ─── Stat pill ────────────────────────────────────────────────────────────────

class _StatPill extends StatelessWidget {
  final String label;
  final IconData icon;
  final double value;
  final bool isLoading;
  final Color color;
  final String prefix;

  const _StatPill({
    required this.label,
    required this.icon,
    required this.value,
    required this.isLoading,
    required this.color,
    this.prefix = '',
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Icon(icon, color: color, size: 11),
              ),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.65),
                  fontSize: 10.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          isLoading
              ? const _Skeleton(width: 56, height: 14)
              : TweenAnimationBuilder<double>(
                  key: ValueKey(value),
                  tween: Tween(begin: 0, end: value),
                  duration: const Duration(milliseconds: 700),
                  curve: Curves.easeOutQuart,
                  builder: (_, val, __) => Text(
                    '$prefix${CurrencyFormatter.formatCompact(val)}',
                    style: TextStyle(
                      color: label == 'Net' ? color : Colors.white,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3,
                    ),
                  ),
                ),
        ],
      ),
    );
  }
}

// ─── Vertical divider ─────────────────────────────────────────────────────────

class _VerticalDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        width: 0.5,
        height: 36,
        color: Colors.white.withOpacity(0.15),
      );
}

// ─── Skeleton placeholder ─────────────────────────────────────────────────────

class _Skeleton extends StatelessWidget {
  final double width;
  final double height;
  const _Skeleton({required this.width, required this.height});

  @override
  Widget build(BuildContext context) => Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(6),
        ),
      );
}