import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/spendly_shimmer.dart';
import '../../../insight/domain/services/insight_engine.dart';

// ─────────────────────────────────────────────────────────────────────────────
// InsightCarousel — v3 (compact + professional)
// ─────────────────────────────────────────────────────────────────────────────

class _InsightStyle {
  final Color accentColor;
  final String label;
  const _InsightStyle({required this.accentColor, required this.label});
}

_InsightStyle _styleFor(String type, bool isWarning) {
  if (isWarning) {
    return _InsightStyle(
      accentColor: type == 'budget_warning' ? AppColors.expense : AppColors.warning,
      label: type == 'budget_warning' ? 'Peringatan Budget' : 'Perhatian',
    );
  }
  switch (type) {
    case 'category_spend':
      return const _InsightStyle(accentColor: AppColors.primary,         label: 'Kategori Terbesar');
    case 'highest_day':
      return const _InsightStyle(accentColor: Color(0xFF7C5DFA),   label: 'Hari Favorit');
    case 'spend_trend':
      return const _InsightStyle(accentColor: Color(0xFF06B6D4),   label: 'Tren Pengeluaran');
    case 'savings':
      return const _InsightStyle(accentColor: Color(0xFF22C55E),   label: 'Tabungan');
    case 'balance_warning':
      return const _InsightStyle(accentColor: AppColors.warning,         label: 'Saldo');
    default:
      return const _InsightStyle(accentColor: AppColors.primary,         label: 'Insight');
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class InsightCarousel extends ConsumerStatefulWidget {
  const InsightCarousel({super.key});

  @override
  ConsumerState<InsightCarousel> createState() => _InsightCarouselState();
}

class _InsightCarouselState extends ConsumerState<InsightCarousel> {
  final PageController _pageCtrl = PageController(viewportFraction: 0.90);
  int _currentPage = 0;

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark        = Theme.of(context).brightness == Brightness.dark;
    final insightsAsync = ref.watch(insightsProvider);

    return insightsAsync.when(
      loading: () => _buildShimmer(isDark),
      error:   (_, __) => const SizedBox.shrink(),
      data: (insights) {
        if (insights.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 92,
              child: PageView.builder(
                controller:    _pageCtrl,
                itemCount:     insights.length,
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemBuilder: (_, i) {
                  final insight = insights[i];
                  final style   = _styleFor(insight.type, insight.isWarning);
                  return _InsightCard(
                    insight: insight,
                    style:   style,
                    isDark:  isDark,
                  );
                },
              ),
            ),

            if (insights.length > 1) ...[
              const SizedBox(height: 10),
              Center(
                child: _DotIndicator(
                  count:   insights.length,
                  current: _currentPage,
                  isDark:  isDark,
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildShimmer(bool isDark) {
    return ShimmerScope(
      child: SizedBox(
        height: 92,
        child: ListView.separated(
          scrollDirection:  Axis.horizontal,
          padding:          const EdgeInsets.symmetric(horizontal: 16),
          itemCount:        3,
          separatorBuilder: (_, __) => const SizedBox(width: 10),
          itemBuilder: (_, __) => Container(
            width: MediaQuery.of(context).size.width * 0.84,
            decoration: BoxDecoration(
              color:        isDark ? AppColors.cardDark : AppColors.card,
              borderRadius: BorderRadius.circular(16),
            ),
            padding: const EdgeInsets.all(14),
            child: const Row(
              children: [
                ShimmerBox(width: 40, height: 40, borderRadius: 12),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment:  MainAxisAlignment.center,
                    children: [
                      ShimmerBox(width: 72, height: 9, borderRadius: 5),
                      SizedBox(height: 7),
                      ShimmerBox(width: double.infinity, height: 11, borderRadius: 5),
                      SizedBox(height: 5),
                      ShimmerBox(width: 120, height: 11, borderRadius: 5),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Kartu ────────────────────────────────────────────────────────────────────

class _InsightCard extends StatelessWidget {
  final InsightData insight;
  final _InsightStyle style;
  final bool isDark;

  const _InsightCard({
    required this.insight,
    required this.style,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final cardBg      = isDark ? AppColors.cardDark : AppColors.card;
    final borderColor = isDark ? AppColors.borderDark : AppColors.border;
    final textPrimary = isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;
    final accent      = style.accentColor;

    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 6),
      child: Container(
        decoration: BoxDecoration(
          color: insight.isWarning
              ? accent.withValues(alpha: isDark ? 0.08 : 0.05)
              : cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: insight.isWarning
                ? accent.withValues(alpha: 0.25)
                : borderColor,
            width: 0.8,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // ── Emoji bubble ───────────────────────────────────────────
            Container(
              width:  40,
              height: 40,
              decoration: BoxDecoration(
                color:        accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(insight.emoji, style: const TextStyle(fontSize: 20)),
              ),
            ),

            const SizedBox(width: 12),

            // ── Teks ───────────────────────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment:  MainAxisAlignment.center,
                children: [
                  Text(
                    style.label.toUpperCase(),
                    style: TextStyle(
                      fontSize:      9.5,
                      fontWeight:    FontWeight.w700,
                      color:         accent,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    insight.message,
                    style: TextStyle(
                      fontSize:   12,
                      fontWeight: FontWeight.w500,
                      color:      textPrimary,
                      height:     1.35,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // ── Arrow hint ─────────────────────────────────────────────
            const SizedBox(width: 6),
            Icon(
              Icons.chevron_right_rounded,
              size:  16,
              color: (isDark ? AppColors.textHintDark : AppColors.textHint)
                  .withValues(alpha: 0.4),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Dot indicator ────────────────────────────────────────────────────────────

class _DotIndicator extends StatelessWidget {
  final int count;
  final int current;
  final bool isDark;

  const _DotIndicator({
    required this.count,
    required this.current,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(count, (i) {
        final isActive = i == current;
        return AnimatedContainer(
          duration:     const Duration(milliseconds: 220),
          curve:        Curves.easeOutCubic,
          margin:       const EdgeInsets.symmetric(horizontal: 2.5),
          width:        isActive ? 14 : 5,
          height:       5,
          decoration: BoxDecoration(
            color: isActive
                ? AppColors.primary
                : (isDark ? AppColors.textHintDark : AppColors.textHint)
                    .withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(3),
          ),
        );
      }),
    );
  }
}