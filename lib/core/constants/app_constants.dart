class AppConstants {
  AppConstants._();

  static const String appName = 'Spendly';
  static const String typeIncome = 'income';
  static const String typeExpense = 'expense';

  // ── Kategori Pengeluaran (30) ─────────────────────────────────────────────
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
    'Pulsa & Kuota',
    'Parkir & Tol',
    'Pakaian & Aksesoris',
    'Donasi & Zakat',
    'Hobi & Komunitas',
    'Skincare & Kosmetik',
    'Lainnya',
  ];

  // ── Kategori Pemasukan (16) ───────────────────────────────────────────────
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
    'Cashback & Reward',
    'Komisi & Affiliate',
    'Warisan & Hibah',
    'Tunjangan & Insentif',
    'Royalti & Hak Cipta',
    'Beasiswa & Gran',
    'Klaim Asuransi',
    'Kripto & Trading',
    'Pengembalian Pajak',
    'Subsidi & Bantuan',
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