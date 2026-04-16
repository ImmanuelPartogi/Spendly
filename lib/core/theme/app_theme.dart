import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

// ─── Animation constants — gunakan di seluruh app ─────────────────────────────
/// Durasi standar micro-interaction (tap, hover, toggle).
const kDurationFast   = Duration(milliseconds: 160);
/// Durasi transisi UI normal (slide, expand, modal).
const kDurationNormal = Duration(milliseconds: 260);
/// Durasi transisi besar (page, hero).
const kDurationSlow   = Duration(milliseconds: 380);

/// Curve premium — snappy, not bouncy.
const kCurveDefault = Curves.easeOutQuart;
/// Curve untuk spring/bounce kecil (FAB, badge).
const kCurveSpring  = Curves.easeOutBack;

class AppTheme {
  AppTheme._();

  // ── Typography helpers ────────────────────────────────────────────────────
  static TextStyle _sora(double size, FontWeight weight, Color color,
      {double? height, double? spacing}) =>
      GoogleFonts.sora(
          fontSize: size,
          fontWeight: weight,
          color: color,
          height: height,
          letterSpacing: spacing);

  static TextStyle _dm(double size, FontWeight weight, Color color,
      {double? height}) =>
      GoogleFonts.dmSans(
          fontSize: size, fontWeight: weight, color: color, height: height);

  static ThemeData get lightTheme => _build(Brightness.light);
  static ThemeData get darkTheme  => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;

    final bg      = isDark ? AppColors.backgroundDark : AppColors.background;
    final card    = isDark ? AppColors.cardDark       : AppColors.card;
    final surface = isDark ? AppColors.surfaceDark    : AppColors.surface;
    final border  = isDark ? AppColors.borderDark     : AppColors.border;
    final div     = isDark ? AppColors.dividerDark    : AppColors.divider;
    final txtP    = isDark ? AppColors.textPrimaryDark   : AppColors.textPrimary;
    final txtS    = isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;
    final txtH    = isDark ? AppColors.textHintDark      : AppColors.textHint;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: brightness,
        primary: AppColors.primary,
        secondary: AppColors.accentPurple,
        surface: surface,
        background: bg,
        error: AppColors.error,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: txtP,
        onBackground: txtP,
      ),

      scaffoldBackgroundColor: bg,

      // ── App Bar ────────────────────────────────────────────────────────────
      appBarTheme: AppBarTheme(
        backgroundColor: bg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        systemOverlayStyle: isDark
            ? SystemUiOverlayStyle.light
                .copyWith(statusBarColor: Colors.transparent)
            : SystemUiOverlayStyle.dark
                .copyWith(statusBarColor: Colors.transparent),
        titleTextStyle: _sora(17, FontWeight.w700, txtP, spacing: -0.4),
        iconTheme: IconThemeData(color: txtP, size: 22),
        actionsIconTheme: IconThemeData(color: txtS, size: 22),
      ),

      // ── Text Theme ─────────────────────────────────────────────────────────
      textTheme: TextTheme(
        displayLarge:  _sora(34, FontWeight.w800, txtP, height: 1.1,  spacing: -1.2),
        displayMedium: _sora(28, FontWeight.w800, txtP, height: 1.15, spacing: -0.9),
        displaySmall:  _sora(24, FontWeight.w700, txtP, height: 1.2,  spacing: -0.6),
        headlineLarge: _sora(22, FontWeight.w700, txtP, height: 1.25, spacing: -0.5),
        headlineMedium:_sora(20, FontWeight.w700, txtP, height: 1.3,  spacing: -0.4),
        headlineSmall: _sora(18, FontWeight.w700, txtP, height: 1.3,  spacing: -0.3),
        titleLarge:    _sora(16, FontWeight.w600, txtP, height: 1.4),
        titleMedium:   _sora(14, FontWeight.w600, txtP, height: 1.4),
        titleSmall:    _dm(12,   FontWeight.w600, txtS, height: 1.4),
        bodyLarge:     _dm(15,   FontWeight.w400, txtP, height: 1.6),
        bodyMedium:    _dm(14,   FontWeight.w400, txtP, height: 1.55),
        bodySmall:     _dm(12,   FontWeight.w400, txtS, height: 1.5),
        labelLarge:    _dm(14,   FontWeight.w600, AppColors.primary),
        labelMedium:   _dm(12,   FontWeight.w500, txtS),
        labelSmall:    _dm(11,   FontWeight.w500, txtH),
      ),

      // ── Card ──────────────────────────────────────────────────────────────
      // Elevation 0 — shadow dikontrol manual di SpendlyCard agar lebih presisi.
      cardTheme: CardTheme(
        color: card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: border, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),

      // ── Input ─────────────────────────────────────────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: border, width: 1)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide:
                const BorderSide(color: AppColors.primary, width: 1.5)),
        errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide:
                const BorderSide(color: AppColors.error, width: 1)),
        focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide:
                const BorderSide(color: AppColors.error, width: 1.5)),
        hintStyle: _dm(14, FontWeight.w400, txtH),
        labelStyle: _dm(14, FontWeight.w500, txtS),
        prefixStyle: _dm(14, FontWeight.w500, txtS),
        floatingLabelStyle:
            _dm(12, FontWeight.w600, AppColors.primary),
      ),

      // ── Elevated Button ───────────────────────────────────────────────────
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor:
              AppColors.primary.withOpacity(0.38),
          disabledForegroundColor: Colors.white.withOpacity(0.55),
          elevation: 0,
          shadowColor: Colors.transparent,
          padding:
              const EdgeInsets.symmetric(horizontal: 24, vertical: 15),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
          textStyle: GoogleFonts.sora(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.1),
          animationDuration: kDurationFast,
        ),
      ),

      // ── Outlined Button ───────────────────────────────────────────────────
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary, width: 1.5),
          padding:
              const EdgeInsets.symmetric(horizontal: 24, vertical: 15),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
          textStyle: GoogleFonts.sora(
              fontSize: 14, fontWeight: FontWeight.w600),
          animationDuration: kDurationFast,
        ),
      ),

      // ── Text Button ───────────────────────────────────────────────────────
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor:
              isDark ? AppColors.primaryLight : AppColors.primary,
          textStyle: GoogleFonts.sora(
              fontSize: 14, fontWeight: FontWeight.w600),
          padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          animationDuration: kDurationFast,
        ),
      ),

      // ── FAB ───────────────────────────────────────────────────────────────
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        focusElevation: 0,
        hoverElevation: 0,
        highlightElevation: 0,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18)),
      ),

      // ── Switch ────────────────────────────────────────────────────────────
      switchTheme: SwitchThemeData(
        thumbColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return Colors.white;
          }
          return isDark ? AppColors.textSecondaryDark : AppColors.textHint;
        }),
        trackColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return AppColors.primary;
          }
          return isDark ? AppColors.surfaceDark : AppColors.surface;
        }),
        trackOutlineColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return Colors.transparent;
          }
          return border;
        }),
      ),

      // ── Chip ──────────────────────────────────────────────────────────────
      chipTheme: ChipThemeData(
        backgroundColor: surface,
        selectedColor: AppColors.primary.withOpacity(0.12),
        labelStyle: _dm(13, FontWeight.w600, txtS),
        side: BorderSide(color: border),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      ),

      // ── Divider ───────────────────────────────────────────────────────────
      dividerTheme:
          DividerThemeData(color: div, thickness: 1, space: 1),

      // ── SnackBar ──────────────────────────────────────────────────────────
      snackBarTheme: SnackBarThemeData(
        backgroundColor:
            isDark ? const Color(0xFF1E2030) : AppColors.textPrimary,
        contentTextStyle:
            _dm(14, FontWeight.w500, Colors.white),
        actionTextColor: AppColors.primaryLight,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14)),
        elevation: 0,
        insetPadding: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 12),
      ),

      // ── Bottom Sheet ──────────────────────────────────────────────────────
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: bg,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(28)),
        ),
        elevation: 0,
        modalElevation: 0,
      ),

      // ── Dialog ────────────────────────────────────────────────────────────
      dialogTheme: DialogTheme(
        backgroundColor: card,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24)),
        titleTextStyle: _sora(18, FontWeight.w700, txtP),
        contentTextStyle:
            _dm(14, FontWeight.w400, txtS, height: 1.55),
      ),

      // ── Tab Bar ───────────────────────────────────────────────────────────
      tabBarTheme: TabBarTheme(
        labelStyle:
            GoogleFonts.sora(fontSize: 14, fontWeight: FontWeight.w700),
        unselectedLabelStyle:
            GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w500),
        labelColor: Colors.white,
        unselectedLabelColor: txtS,
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
      ),

      // ── Popup Menu ────────────────────────────────────────────────────────
      popupMenuTheme: PopupMenuThemeData(
        color: card,
        surfaceTintColor: Colors.transparent,
        elevation: 8,
        shadowColor: Colors.black.withOpacity(0.1),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14)),
        textStyle: _dm(14, FontWeight.w500, txtP),
      ),

      // ── Icon ──────────────────────────────────────────────────────────────
      iconTheme: IconThemeData(color: txtS, size: 22),
      primaryIconTheme:
          const IconThemeData(color: Colors.white, size: 22),

      // ── Progress Indicator ────────────────────────────────────────────────
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primary,
        linearMinHeight: 6,
      ),

      // ── Page Transitions ──────────────────────────────────────────────────
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: _SlideUpFadeTransition(),
          TargetPlatform.iOS:     CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }
}

// ── Page transition: slide-up + fade (lebih modern dari slide kiri) ───────────
class _SlideUpFadeTransition extends PageTransitionsBuilder {
  const _SlideUpFadeTransition();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    // Incoming: slide up 3% + fade in
    final fadeIn = CurvedAnimation(
        parent: animation, curve: kDurationNormal.inMilliseconds > 0
            ? const Interval(0.0, 1.0, curve: Curves.easeOutQuart)
            : Curves.linear);
    final slideIn = Tween<Offset>(
            begin: const Offset(0, 0.03), end: Offset.zero)
        .animate(fadeIn);

    // Outgoing: slight scale-down + fade
    final fadeOut = Tween<double>(begin: 1.0, end: 0.97).animate(
        CurvedAnimation(
            parent: secondaryAnimation, curve: Curves.easeIn));

    return FadeTransition(
      opacity: fadeOut,
      child: FadeTransition(
        opacity: fadeIn,
        child: SlideTransition(position: slideIn, child: child),
      ),
    );
  }
}