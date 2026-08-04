class AppConstants {
  AppConstants._();

  static const String appName = 'Spendly';
  static const String typeIncome = 'income';
  static const String typeExpense = 'expense';

  // ── Kategori Pengeluaran (24) ─────────────────────────────────────────────
  static const List<String> expenseCategories = [
    'Makanan & Minuman',
    'Transportasi',
    'Bahan Bakar',
    'Belanja',
    'Hiburan',
    'Kesehatan',
    'Tagihan & Utilitas',
    'Pendidikan',
    'Perawatan Diri',
    'Rumah & Perabot',
    'Rumah Tangga',
    'Anak & Bayi',
    'Pajak & Retribusi',
    'Utang & Cicilan',
    'Transfer/Kirim Uang',
    'Elektronik',
    'Perjalanan',
    'Restoran & Kafe',
    'Langganan',
    'Asuransi',
    'Olahraga',
    'Hadiah & Amal',
    'Hewan Peliharaan',
    'Lainnya',
  ];

  // ── Kategori Pemasukan (14) ───────────────────────────────────────────────
  static const List<String> incomeCategories = [
    'Gaji',
    'Freelance',
    'Bisnis',
    'Investasi',
    'Bonus',
    'Hadiah',
    'Uang Saku/THR',
    'Refund',
    'Pinjaman Diterima',
    'Hasil Jual Barang',
    'Sewa',
    'Dividen',
    'Kerja Sampingan',
    'Lainnya',
  ];

  static const String periodMonthly = 'monthly';

  static const List<String> daysOfWeek = [
    'Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min',
  ];

  static const List<String> daysOfWeekFull = [
    'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu',
  ];

  static const int defaultUserId = 1;
}