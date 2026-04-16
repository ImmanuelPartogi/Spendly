import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
// CategoryUtils — semua ikon menggunakan Material Icons, TANPA emoji
// Konsisten, clean, dan professional di semua tema/platform
// ─────────────────────────────────────────────────────────────────────────────

class CategoryUtils {
  CategoryUtils._();

  // ── Icon ──────────────────────────────────────────────────────────────────

  static IconData getIcon(String category) {
    return _iconMap[category] ?? Icons.receipt_long_rounded;
  }

  // ── Color ─────────────────────────────────────────────────────────────────

  static Color getColor(String category) {
    return _colorMap[category] ?? const Color(0xFF6B7280);
  }

  // ── Label pendek untuk grid 3 kolom ───────────────────────────────────────

  static String getShortLabel(String category) {
    const m = {
      'Food & Drink':       'Food',
      'Health & Medical':   'Health',
      'Bills & Utilities':  'Bills',
      'Personal Care':      'Care',
      'Home & Furniture':   'Home',
      'Restaurant & Cafe':  'Resto',
      'Sport & Fitness':    'Sport',
      'Gifts & Charity':    'Gifts',
      'Entertainment':      'Fun',
      'Transportation':     'Travel',
      'E-Commerce':         'Online',
      'Investment':         'Invest',
    };
    return m[category] ?? category;
  }

  // ─── Maps ─────────────────────────────────────────────────────────────────

  static const Map<String, IconData> _iconMap = {
    // Expense
    'Food & Drink':       Icons.local_cafe_rounded,
    'Restaurant & Cafe':  Icons.restaurant_rounded,
    'Transportation':     Icons.directions_car_rounded,
    'Shopping':           Icons.shopping_bag_rounded,
    'Entertainment':      Icons.movie_rounded,
    'Health & Medical':   Icons.local_hospital_rounded,
    'Bills & Utilities':  Icons.receipt_rounded,
    'Education':          Icons.school_rounded,
    'Personal Care':      Icons.spa_rounded,
    'Home & Furniture':   Icons.home_rounded,
    'Sport & Fitness':    Icons.fitness_center_rounded,
    'Gifts & Charity':    Icons.card_giftcard_rounded,
    'Travel':             Icons.flight_rounded,
    'Subscriptions':      Icons.subscriptions_rounded,
    'Insurance':          Icons.security_rounded,
    'Pet':                Icons.pets_rounded,
    'E-Commerce':         Icons.storefront_rounded,
    'Other':              Icons.more_horiz_rounded,

    // Income
    'Salary':             Icons.account_balance_wallet_rounded,
    'Freelance':          Icons.laptop_rounded,
    'Business':           Icons.business_center_rounded,
    'Investment':         Icons.trending_up_rounded,
    'Gift':               Icons.redeem_rounded,
    'Rental Income':      Icons.apartment_rounded,
    'Cashback':           Icons.savings_rounded,
    'Bonus':              Icons.star_rounded,
    'Allowance':          Icons.payments_rounded,
    'Other Income':       Icons.add_circle_rounded,
  };

  static const Map<String, Color> _colorMap = {
    // Expense — warna hangat/netral
    'Food & Drink':       Color(0xFFEF6C00),
    'Restaurant & Cafe':  Color(0xFFE53935),
    'Transportation':     Color(0xFF1E88E5),
    'Shopping':           Color(0xFF8E24AA),
    'Entertainment':      Color(0xFFD81B60),
    'Health & Medical':   Color(0xFF00ACC1),
    'Bills & Utilities':  Color(0xFF546E7A),
    'Education':          Color(0xFF3949AB),
    'Personal Care':      Color(0xFFEC407A),
    'Home & Furniture':   Color(0xFF6D4C41),
    'Sport & Fitness':    Color(0xFF43A047),
    'Gifts & Charity':    Color(0xFFFF7043),
    'Travel':             Color(0xFF00897B),
    'Subscriptions':      Color(0xFF5C6BC0),
    'Insurance':          Color(0xFF78909C),
    'Pet':                Color(0xFF8D6E63),
    'E-Commerce':         Color(0xFF1565C0),
    'Other':              Color(0xFF757575),

    // Income — warna hijau/biru segar
    'Salary':             Color(0xFF2E7D32),
    'Freelance':          Color(0xFF00695C),
    'Business':           Color(0xFF1565C0),
    'Investment':         Color(0xFF283593),
    'Gift':               Color(0xFFC62828),
    'Rental Income':      Color(0xFF4527A0),
    'Cashback':           Color(0xFF00838F),
    'Bonus':              Color(0xFFF57F17),
    'Allowance':          Color(0xFF37474F),
    'Other Income':       Color(0xFF558B2F),
  };
}