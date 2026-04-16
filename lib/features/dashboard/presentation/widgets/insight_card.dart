import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/spendly_card.dart';
import '../../../../shared/widgets/spendly_shimmer.dart';

class InsightCarousel extends ConsumerWidget {
  const InsightCarousel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark   = Theme.of(context).brightness == Brightness.dark;
    final txtColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;

    final insightsAsync = ref.watch(insightsProvider);

    return insightsAsync.when(
      loading: () => SizedBox(
        height: 76,
        child: ShimmerScope(
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: 3,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (_, __) => SpendlyCard(
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Emoji placeholder
                  ShimmerBox(
                    width: 28,
                    height: 28,
                    borderRadius: 6,
                  ),
                  const SizedBox(width: 10),
                  // Text placeholder
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ShimmerBox(
                        width: 160,
                        height: 11,
                        borderRadius: 6,
                      ),
                      const SizedBox(height: 6),
                      ShimmerBox(
                        width: 110,
                        height: 11,
                        borderRadius: 6,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      error: (_, __) => const SizedBox.shrink(),
      data: (insights) {
        if (insights.isEmpty) return const SizedBox.shrink();

        return SizedBox(
          height: 76,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: insights.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (_, i) {
              final insight = insights[i];

              return SpendlyCard(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                color: insight.isWarning
                    ? AppColors.warning.withOpacity(0.10)
                    : null,
                child: SizedBox(
                  width: 220,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(insight.emoji,
                          style: const TextStyle(fontSize: 22)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          insight.message,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w500,
                            color: insight.isWarning
                                ? AppColors.warning
                                : txtColor,
                            height: 1.4,
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}