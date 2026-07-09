import 'package:flutter/material.dart';
import '../../core/theme/app_spacing.dart';

/// Premium staggered entrance animation wrapper.
///
/// Wraps any widget to give it a fade + slight upward motion entrance
/// with an optional stagger delay for list-based UIs.
///
/// Usage:
/// ```dart
/// SpendlyStaggeredItem(index: 0, child: MyCard())
/// SpendlyStaggeredItem(child: MyCard())  // auto-delay based on index
/// ```
class SpendlyStaggeredItem extends StatefulWidget {
  final Widget child;
  final int index;
  final Duration? customDelay;
  final bool enabled;

  const SpendlyStaggeredItem({
    super.key,
    required this.child,
    this.index = 0,
    this.customDelay,
    this.enabled = true,
  });

  @override
  State<SpendlyStaggeredItem> createState() => _SpendlyStaggeredItemState();
}

class _SpendlyStaggeredItemState extends State<SpendlyStaggeredItem>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: AppMotion.dSlow,
    );
    _fade = CurvedAnimation(parent: _ctrl, curve: AppMotion.cEnter);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: AppMotion.cEnter));

    if (widget.enabled) {
      final delay = widget.customDelay ??
          Duration(
            milliseconds: AppMotion.staggerDelay.inMilliseconds *
                widget.index.clamp(0, 8),
          );
      Future.delayed(delay, () {
        if (mounted) _ctrl.forward();
      });
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return widget.child;
    return RepaintBoundary(
      child: FadeTransition(
        opacity: _fade,
        child: SlideTransition(
          position: _slide,
          child: widget.child,
        ),
      ),
    );
  }
}

/// Animated press feedback for any tappable widget.
/// Scales down 4% + subtle opacity shift on press — premium tactile feel.
///
/// Usage:
/// ```dart
/// SpendlyPressable(
///   onTap: () {},
///   child: MyCard(),
/// )
/// ```
class SpendlyPressable extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double scaleDown;

  const SpendlyPressable({
    super.key,
    required this.child,
    this.onTap,
    this.scaleDown = 0.96,
  });

  @override
  State<SpendlyPressable> createState() => _SpendlyPressableState();
}

class _SpendlyPressableState extends State<SpendlyPressable>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: AppMotion.dFast,
      reverseDuration: const Duration(milliseconds: 220),
    );
    _scale = Tween<double>(begin: 1.0, end: widget.scaleDown).animate(
      CurvedAnimation(parent: _ctrl, curve: AppMotion.cSmooth),
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
      onTapDown: (_) {
        if (widget.onTap != null) _ctrl.forward();
      },
      onTapUp: (_) {
        _ctrl.reverse();
        widget.onTap?.call();
      },
      onTapCancel: () => _ctrl.reverse(),
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: _scale,
        builder: (_, child) => Transform.scale(
          scale: _scale.value,
          child: child,
        ),
        child: widget.child,
      ),
    );
  }
}

/// Skeleton loader block — base unit for shimmer loading states.
///
/// Usage:
/// ```dart
/// SpendlySkeleton(width: 120, height: 16)
/// SpendlySkeleton.circle(size: 40)  // for avatars
/// ```
class SpendlySkeleton extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;
  final bool isCircle;

  const SpendlySkeleton({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 8,
    this.isCircle = false,
  });

  const SpendlySkeleton.circle({
    super.key,
    required double size,
  })  : width = size,
        height = size,
        borderRadius = 0,
        isCircle = true;

  @override
  State<SpendlySkeleton> createState() => _SpendlySkeletonState();
}

class _SpendlySkeletonState extends State<SpendlySkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor =
        isDark ? const Color(0xFF1E2030) : const Color(0xFFE2E7F3);
    final highlightColor =
        isDark ? const Color(0xFF272A3A) : const Color(0xFFEEF1FA);

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        final progress = _ctrl.value;
        // Shimmer sweeps left to right
        final shimmerProgress = (progress * 2) % 1.0;
        final isHighlight = shimmerProgress > 0.5;

        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: isHighlight ? highlightColor : baseColor,
            borderRadius:
                widget.isCircle ? null : BorderRadius.circular(widget.borderRadius),
            shape: widget.isCircle ? BoxShape.circle : BoxShape.rectangle,
          ),
        );
      },
    );
  }
}

/// Premium skeleton layout for a full card with title, value, and rows.
/// Use as placeholder while data is loading.
class SpendlyCardSkeleton extends StatelessWidget {
  final int rowCount;
  final bool showHeader;

  const SpendlyCardSkeleton({
    super.key,
    this.rowCount = 3,
    this.showHeader = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: AppSpacing.brLarge,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showHeader) ...[
            Row(
              children: [
                const SpendlySkeleton(width: 100, height: 14),
                const Spacer(),
                const SpendlySkeleton(width: 50, height: 22, borderRadius: 20),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          ...List.generate(rowCount, (i) {
            return Padding(
              padding: EdgeInsets.only(
                top: i == 0 ? 0 : AppSpacing.md,
              ),
              child: const Row(
                children: [
                  SpendlySkeleton.circle(size: 36),
                  SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SpendlySkeleton(width: 120, height: 12),
                        SizedBox(height: 6),
                        SpendlySkeleton(width: 80, height: 10),
                      ],
                    ),
                  ),
                  SpendlySkeleton(width: 60, height: 12),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

/// Animated number count-up widget.
/// Counts from 0 → target with easeOutQuart curve.
///
/// Usage:
/// ```dart
/// SpendlyAnimatedNumber(
///   value: 1500000,
///   prefix: 'Rp ',
///   formatCompact: true,
/// )
/// ```
class SpendlyAnimatedNumber extends StatelessWidget {
  final double value;
  final String prefix;
  final String suffix;
  final TextStyle? style;
  final bool formatCompact;
  final Duration duration;

  const SpendlyAnimatedNumber({
    super.key,
    required this.value,
    this.prefix = '',
    this.suffix = '',
    this.style,
    this.formatCompact = false,
    this.duration = AppMotion.countUp,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      key: ValueKey(value),
      tween: Tween(begin: 0, end: value),
      duration: duration,
      curve: AppMotion.cEnter,
      builder: (_, val, __) {
        return Text(
          '$prefix${_format(val)}$suffix',
          style: style,
        );
      },
    );
  }

  String _format(double val) {
    if (formatCompact) {
      if (val.abs() >= 1000000000) {
        return '${(val / 1000000000).toStringAsFixed(1)} M';
      } else if (val.abs() >= 1000000) {
        return '${(val / 1000000).toStringAsFixed(1)} jt';
      } else if (val.abs() >= 1000) {
        return '${(val / 1000).toStringAsFixed(0)} rb';
      }
    }
    return val.toStringAsFixed(0);
  }
}