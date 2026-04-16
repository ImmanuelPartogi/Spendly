import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ── Brand ───────────────────────────────────────────────────────────────────
  static const Color primary       = Color(0xFF4F6EF7);
  static const Color primaryLight  = Color(0xFF7B93FF);
  static const Color primaryDark   = Color(0xFF2E4DD4);

  // ── Semantic ────────────────────────────────────────────────────────────────
  static const Color income  = Color(0xFF10C27A);
  static const Color expense = Color(0xFFFF5B79);
  static const Color warning = Color(0xFFFFC043);
  static const Color success = Color(0xFF10C27A);
  static const Color error   = Color(0xFFFF5B79);

  // ── Accent ──────────────────────────────────────────────────────────────────
  static const Color accentPurple = Color(0xFF8B6BED);
  static const Color accentTeal   = Color(0xFF00CEAF);
  static const Color accentOrange = Color(0xFFFF7B50);

  // ── Category ────────────────────────────────────────────────────────────────
  static const Color catFood          = Color(0xFFFF7B50);
  static const Color catTransport     = Color(0xFF4F6EF7);
  static const Color catShopping      = Color(0xFFFF5B79);
  static const Color catEntertainment = Color(0xFF8B6BED);
  static const Color catHealth        = Color(0xFF10C27A);
  static const Color catBills         = Color(0xFFFFC043);
  static const Color catSalary        = Color(0xFF00CEAF);
  static const Color catOthers        = Color(0xFF7A849A);

  // ── Light Surface ────────────────────────────────────────────────────────────
  static const Color background = Color(0xFFF4F6FB);
  static const Color card       = Color(0xFFFFFFFF);
  static const Color surface    = Color(0xFFEEF1FA);
  static const Color border     = Color(0xFFE2E7F3);
  static const Color divider    = Color(0xFFECEFF8);

  // ── Light Text ───────────────────────────────────────────────────────────────
  static const Color textPrimary   = Color(0xFF111827);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textHint      = Color(0xFFADB5C9);

  // ── Dark Surface ─────────────────────────────────────────────────────────────
  static const Color backgroundDark = Color(0xFF0C0E14);
  static const Color cardDark       = Color(0xFF161820);
  static const Color surfaceDark    = Color(0xFF1E2030);
  static const Color borderDark     = Color(0xFF272A3A);
  static const Color dividerDark    = Color(0xFF1E2030);

  // ── Dark Text ────────────────────────────────────────────────────────────────
  static const Color textPrimaryDark   = Color(0xFFF1F2F8);
  static const Color textSecondaryDark = Color(0xFF8B91A8);
  static const Color textHintDark      = Color(0xFF3E4460);

  // ── Gradients ────────────────────────────────────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF4F6EF7), Color(0xFF8B6BED)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient incomeGradient = LinearGradient(
    colors: [Color(0xFF10C27A), Color(0xFF00E5A0)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient expenseGradient = LinearGradient(
    colors: [Color(0xFFFF5B79), Color(0xFFFF8FA0)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkCardGradient = LinearGradient(
    colors: [Color(0xFF1A1D2E), Color(0xFF161820)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// BuildContext extension — theme-adaptive colors
// Gunakan ini di seluruh widget GANTI hardcoded AppColors.textPrimary dll.
// ─────────────────────────────────────────────────────────────────────────────

extension AppColorsContext on BuildContext {
  bool get isDark => Theme.of(this).brightness == Brightness.dark;

  // Surfaces
  Color get bgColor     => isDark ? AppColors.backgroundDark : AppColors.background;
  Color get cardColor   => isDark ? AppColors.cardDark       : AppColors.card;
  Color get surfaceColor=> isDark ? AppColors.surfaceDark    : AppColors.surface;
  Color get borderColor => isDark ? AppColors.borderDark     : AppColors.border;
  Color get dividerColor=> isDark ? AppColors.dividerDark    : AppColors.divider;

  // Text
  Color get textPrimary   => isDark ? AppColors.textPrimaryDark   : AppColors.textPrimary;
  Color get textSecondary => isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;
  Color get textHint      => isDark ? AppColors.textHintDark      : AppColors.textHint;
}