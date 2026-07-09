import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

// ─────────────────────────────────────────────────────────────────────────────
// SectionHeader — Polished section header with optional badge & accent line
//
// Improvements:
// - Optional `count` badge (jumlah item)
// - Animated TextButton action dengan underline hover effect
// - `showAccent` → garis kiri berwarna
// ─────────────────────────────────────────────────────────────────────────────

class SectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  /// Warna judul — kalau null, otomatis ikut theme
  final Color? titleColor;

  /// Tampilkan badge count di samping title
  final int? count;

  /// Tampilkan aksen garis kiri berwarna primary
  final bool showAccent;

  const SectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
    this.titleColor,
    this.count,
    this.showAccent = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark   = Theme.of(context).brightness == Brightness.dark;
    final color    = titleColor
        ?? (isDark ? AppColors.textPrimaryDark : AppColors.textPrimary);
    final txtSec   = isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;

    final Widget titleWidget = Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Optional left accent bar
        if (showAccent) ...[
          Container(
            width: 3,
            height: 16,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
        ],

        // Title text
        Text(
          title,
          style: TextStyle(
            fontSize: 15.5,
            fontWeight: FontWeight.w700,
            color: color,
            letterSpacing: -0.3,
            height: 1.0,
          ),
        ),

        // Optional count badge
        if (count != null) ...[
          const SizedBox(width: 7),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.surfaceDark
                  : AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark ? AppColors.borderDark : AppColors.border,
                width: 1,
              ),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                color: txtSec,
                letterSpacing: 0,
              ),
            ),
          ),
        ],
      ],
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        titleWidget,
        const Spacer(),

        // Action button
        if (actionLabel != null)
          _ActionLink(
            label: actionLabel!,
            onTap: onAction,
          ),
      ],
    );
  }
}

// ─── Subtle action link ───────────────────────────────────────────────────────

class _ActionLink extends StatefulWidget {
  final String label;
  final VoidCallback? onTap;
  const _ActionLink({required this.label, this.onTap});

  @override
  State<_ActionLink> createState() => _ActionLinkState();
}

class _ActionLinkState extends State<_ActionLink> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => setState(() => _hovered = true),
      onTapUp: (_) => setState(() => _hovered = false),
      onTapCancel: () => setState(() => _hovered = false),
      child: AnimatedOpacity(
        opacity: _hovered ? 0.65 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.label,
              style: const TextStyle(
                fontSize: 12.5,
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.1,
              ),
            ),
            const SizedBox(width: 2),
            const Icon(
              Icons.chevron_right_rounded,
              size: 15,
              color: AppColors.primary,
            ),
          ],
        ),
      ),
    );
  }
}