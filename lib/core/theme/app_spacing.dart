import 'package:flutter/material.dart';

/// Unified Spacing & Radius Design Tokens for Spendly.
///
/// Use these strict tokens everywhere — no arbitrary spacing values.
/// This ensures pixel-perfect consistency across all screens.
class AppSpacing {
  AppSpacing._();

  // ── Spacing Scale (multiples of 4) ────────────────────────────────────────
  static const double xs2  = 2;
  static const double xs   = 4;
  static const double sm   = 8;
  static const double md   = 12;
  static const double base = 16;
  static const double lg   = 20;
  static const double xl   = 24;
  static const double xl2  = 32;
  static const double xl3  = 40;
  static const double xl4  = 48;
  static const double xl5  = 64;

  // ── Border Radius Scale ───────────────────────────────────────────────────
  /// 12px — chips, small badges, toggles
  static const double rSmall  = 12;

  /// 16px — standard cards, inputs, list items
  static const double rMedium = 16;

  /// 20px — primary cards, containers, bottom sheets inner
  static const double rLarge  = 20;

  /// 24px — hero cards, modals, full-width panels
  static const double rXLarge = 24;

  /// 28px — bottom sheet top corners
  static const double rHero   = 28;

  /// 32px — full-screen dialogs, large containers
  static const double rMega   = 32;

  // ── Convenience BorderRadius presets ──────────────────────────────────────
  static const BorderRadius brSmall  = BorderRadius.all(Radius.circular(rSmall));
  static const BorderRadius brMedium = BorderRadius.all(Radius.circular(rMedium));
  static const BorderRadius brLarge  = BorderRadius.all(Radius.circular(rLarge));
  static const BorderRadius brXLarge = BorderRadius.all(Radius.circular(rXLarge));
  static const BorderRadius brHero   = BorderRadius.all(Radius.circular(rHero));
  static const BorderRadius brMega   = BorderRadius.all(Radius.circular(rMega));

  /// Bottom sheet top radius
  static const BorderRadius brSheetTop = BorderRadius.vertical(
    top: Radius.circular(rHero),
  );

  // ── Page Padding ──────────────────────────────────────────────────────────
  static const EdgeInsets pagePadding = EdgeInsets.symmetric(horizontal: base);
  static const EdgeInsets pagePaddingLg = EdgeInsets.symmetric(horizontal: lg);

  // ── Card Padding ──────────────────────────────────────────────────────────
  static const EdgeInsets cardPadding = EdgeInsets.all(base);
  static const EdgeInsets cardPaddingLg = EdgeInsets.all(lg);
  static const EdgeInsets cardPaddingSM = EdgeInsets.all(md);

  // ── Component Heights ─────────────────────────────────────────────────────
  static const double touchTarget   = 44; // minimum iOS touch target
  static const double buttonHeight  = 48;
  static const double navBarHeight  = 64;
  static const double appBarHeight  = 56;
  static const double fabSize       = 56;
}

/// Unified Elevation / Shadow tokens.
/// Soft, layered, fintech-grade — never harsh.
class AppElevation {
  AppElevation._();

  /// Subtle shadow for flat cards (light mode).
  static List<BoxShadow> flat(Color tint) => [
    BoxShadow(
      color: tint.withValues(alpha: 0.05),
      blurRadius: 10,
      offset: const Offset(0, 2),
      spreadRadius: -1,
    ),
  ];

  /// Standard elevation for interactive cards.
  static List<BoxShadow> raised(Color tint) => [
    BoxShadow(
      color: tint.withValues(alpha: 0.08),
      blurRadius: 16,
      offset: const Offset(0, 4),
      spreadRadius: -2,
    ),
    BoxShadow(
      color: tint.withValues(alpha: 0.04),
      blurRadius: 32,
      offset: const Offset(0, 8),
      spreadRadius: -4,
    ),
  ];

  /// Hero elevation for balance cards & FAB.
  static List<BoxShadow> hero(Color tint) => [
    BoxShadow(
      color: tint.withValues(alpha: 0.18),
      blurRadius: 24,
      offset: const Offset(0, 8),
      spreadRadius: -4,
    ),
    BoxShadow(
      color: tint.withValues(alpha: 0.08),
      blurRadius: 56,
      offset: const Offset(0, 16),
      spreadRadius: -8,
    ),
  ];

  /// Dark mode shadow — deep but subtle.
  static List<BoxShadow> dark = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.35),
      blurRadius: 20,
      offset: const Offset(0, 6),
      spreadRadius: -2,
    ),
  ];

  /// Nav bar shadow.
  static List<BoxShadow> navBar(Color tint) => [
    BoxShadow(
      color: tint.withValues(alpha: 0.12),
      blurRadius: 24,
      offset: const Offset(0, 8),
      spreadRadius: -4,
    ),
  ];
}

/// Unified animation duration & curve tokens.
class AppMotion {
  AppMotion._();

  // ── Durations ─────────────────────────────────────────────────────────────
  static const Duration dFast   = Duration(milliseconds: 160);
  static const Duration dNormal = Duration(milliseconds: 260);
  static const Duration dSlow   = Duration(milliseconds: 380);
  static const Duration dHero   = Duration(milliseconds: 520);

  // ── Curves ────────────────────────────────────────────────────────────────
  static const Curve cDefault  = Curves.easeOutCubic;
  static const Curve cSmooth   = Curves.fastOutSlowIn;
  static const Curve cEnter    = Curves.easeOutQuart;
  static const Curve cExit     = Curves.easeInQuart;
  static const Curve cSpring   = Curves.easeOutBack;
  static const Curve cBounce   = Curves.elasticOut;

  /// Standard stagger delay between list items.
  static const Duration staggerDelay = Duration(milliseconds: 60);

  /// Standard count-up animation duration.
  static const Duration countUp = Duration(milliseconds: 900);
}