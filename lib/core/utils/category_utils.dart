import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
// CategoryUtils — semua ikon menggunakan Material Icons, TANPA emoji
// Key kategori disesuaikan dengan AppConstants (Bahasa Indonesia)
// ─────────────────────────────────────────────────────────────────────────────

class CategoryUtils {
  CategoryUtils._();

  // ── Ikon ──────────────────────────────────────────────────────────────────

  static IconData getIcon(String category) {
    return _iconMap[category] ?? Icons.receipt_long_rounded;
  }

  // ── Warna ─────────────────────────────────────────────────────────────────

  static Color getColor(String category) {
    return _colorMap[category] ?? const Color(0xFF6B7280);
  }

  // ── Label pendek untuk grid 3 kolom ───────────────────────────────────────

  static String getShortLabel(String category) {
    const m = {
      'Makanan & Minuman':  'Makanan',
      'Tagihan & Utilitas': 'Tagihan',
      'Perawatan Diri':     'Perawatan',
      'Rumah & Perabot':    'Rumah',
      'Restoran & Kafe':    'Restoran',
      'Hadiah & Amal':      'Hadiah',
      'Hewan Peliharaan':   'Hewan',
      'Kerja Sampingan':    'Sampingan',
    };
    return m[category] ?? category;
  }

  // ─── Maps ─────────────────────────────────────────────────────────────────

  static const Map<String, IconData> _iconMap = {
    // Pengeluaran
    'Makanan & Minuman':  Icons.local_cafe_rounded,
    'Restoran & Kafe':    Icons.restaurant_rounded,
    'Transportasi':       Icons.directions_car_rounded,
    'Belanja':            Icons.shopping_bag_rounded,
    'Hiburan':            Icons.movie_rounded,
    'Kesehatan':          Icons.local_hospital_rounded,
    'Tagihan & Utilitas': Icons.receipt_rounded,
    'Pendidikan':         Icons.school_rounded,
    'Perawatan Diri':     Icons.spa_rounded,
    'Rumah & Perabot':    Icons.home_rounded,
    'Elektronik':         Icons.devices_rounded,
    'Olahraga':           Icons.fitness_center_rounded,
    'Hadiah & Amal':      Icons.card_giftcard_rounded,
    'Perjalanan':         Icons.flight_rounded,
    'Langganan':          Icons.subscriptions_rounded,
    'Asuransi':           Icons.security_rounded,
    'Hewan Peliharaan':   Icons.pets_rounded,
    'Lainnya':            Icons.more_horiz_rounded,

    // Pemasukan
    'Gaji':           Icons.account_balance_wallet_rounded,
    'Freelance':      Icons.laptop_rounded,
    'Bisnis':         Icons.business_center_rounded,
    'Investasi':      Icons.trending_up_rounded,
    'Hadiah':         Icons.redeem_rounded,
    'Sewa':           Icons.apartment_rounded,
    'Dividen':        Icons.savings_rounded,
    'Bonus':          Icons.star_rounded,
    'Kerja Sampingan':Icons.work_outline_rounded,
  };

  static const Map<String, Color> _colorMap = {
    // Pengeluaran — warna hangat/netral
    'Makanan & Minuman':  Color(0xFFEF6C00),
    'Restoran & Kafe':    Color(0xFFE53935),
    'Transportasi':       Color(0xFF1E88E5),
    'Belanja':            Color(0xFF8E24AA),
    'Hiburan':            Color(0xFFD81B60),
    'Kesehatan':          Color(0xFF00ACC1),
    'Tagihan & Utilitas': Color(0xFF546E7A),
    'Pendidikan':         Color(0xFF3949AB),
    'Perawatan Diri':     Color(0xFFEC407A),
    'Rumah & Perabot':    Color(0xFF6D4C41),
    'Elektronik':         Color(0xFF1565C0),
    'Olahraga':           Color(0xFF43A047),
    'Hadiah & Amal':      Color(0xFFFF7043),
    'Perjalanan':         Color(0xFF00897B),
    'Langganan':          Color(0xFF5C6BC0),
    'Asuransi':           Color(0xFF78909C),
    'Hewan Peliharaan':   Color(0xFF8D6E63),
    'Lainnya':            Color(0xFF757575),

    // Pemasukan — warna hijau/biru segar
    'Gaji':           Color(0xFF2E7D32),
    'Freelance':      Color(0xFF00695C),
    'Bisnis':         Color(0xFF1565C0),
    'Investasi':      Color(0xFF283593),
    'Hadiah':         Color(0xFFC62828),
    'Sewa':           Color(0xFF4527A0),
    'Dividen':        Color(0xFF00838F),
    'Bonus':          Color(0xFFF57F17),
    'Kerja Sampingan':Color(0xFF37474F),
  };
}