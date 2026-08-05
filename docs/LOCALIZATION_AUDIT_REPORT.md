# EXECUTIVE SUMMARY

- **Total File yang Diperiksa**: 152 file (139 file `.dart` di folder `lib/` + 13 file `.json` di folder `assets/translations/`)
- **Total Issue Ditemukan**: ~1,675 temuan teridentifikasi melalui analisis statis (1,213 kemunculan string user-visible hardcoded, 144 key translasi tidak terrefrensi, 13 file translasi terdeteksi korupsi encoding mojibake, 4 instansiasi locale hardcoded pada formatters, 28 string notifikasi hardcoded, 20 label ekspor hardcoded, 54 string parser OCR hardcoded, 70 string insight AI hardcoded, 156 entri lookup kategori hardcoded, 67 entri konstanta hardcoded)
- **Localization Coverage**: **16.5%** (Berdasarkan pengukuran statis: 240 pemanggilan `.tr()` dibanding 1,453 total lokasi string antarmuka pengguna)
- **Architecture Score**: **2.5 / 10** (Berdasarkan evaluasi arsitektur: reverse string-to-key lookup pada utils, hardcoded locale pada formatters, domain layer mengembalikan teks Bahasa Indonesia mentah, service layer mengabaikan locale aktif, 44.4% key translasi tidak terpakai, serta karakter encoding mojibake pada aset JSON)
- **Production Readiness**: **NOT READY (UNFIT FOR MULTI-LANGUAGE PRODUCTION)**
- **Confidence Level**: **High (Berdasarkan pemindaian statis menyeluruh terhadap file source code tanpa sampling)**

---

# ARCHITECTURE REVIEW

## Kelebihan (Strengths)
1. **Penggunaan Package Standar Production**: Memakai `easy_localization` ^3.0.8 yang terintegrasi dengan `MaterialApp` via `localizationsDelegates`, `supportedLocales`, dan `locale` di [main.dart](file:///e:/Nero/Spendly/lib/main.dart#L105-L129).
2. **Dukungan Multabahasa Luas (13 Kode Locale)**: Memiliki 13 file JSON translasi di `assets/translations/` (`id`, `en`, `ms`, `es`, `zh`, `hi`, `fr`, `pt`, `ja`, `de`, `ru`, `ko`, `vi`).
3. **Penggunaan Context Extensions**: Beberapa UI widget menggunakan ekstensi `.tr()` pada key yang terdaftar.

## Kekurangan (Weaknesses & Flaws)
1. **Keterikatan Arsitektur Reverse String-to-Key (`CategoryUtils`)**: Database menyimpan string kategori Bahasa Indonesia mentah (seperti `'Makanan & Minuman'`), kemudian [category_utils.dart](file:///e:/Nero/Spendly/lib/core/utils/category_utils.dart#L37-L92) melakukan mapping terbalik dari string Indonesia ke key translasi (`cat_makanan_minuman`). Jika nama kategori di-input dalam Bahasa Inggris atau bahasa lain, lookup bernilai `null` dan mengembalikan string mentah.
2. **Pencemaran Domain Layer (`InsightEngine`, `OcrParserService`)**: Layer bisnis/domain menghasilkan kalimat Bahasa Indonesia lengkap (misalnya *'75% pengeluaran bulan ini berasal dari kategori Makanan & Minuman'*) dan mengembalikannya dalam entity/model. UI menerima string terformat tanpa mekanisme pembaruan translasi saat runtime locale berubah.
3. **Bypass Formatting oleh Core Utils (`DateFormatter`, `CurrencyFormatter`)**: [date_formatter.dart](file:///e:/Nero/Spendly/lib/core/utils/date_formatter.dart#L20-L22) mengunci locale `'id'` pada objek `DateFormat` dan mengembalikan string tanggal relatif hardcoded (`'Hari ini'`, `'Kemarin'`). [currency_formatter.dart](file:///e:/Nero/Spendly/lib/core/utils/currency_formatter.dart#L6-L11) mengunci locale `'id_ID'` dan simbol `'Rp '`.
4. **Service Layer Tidak Terlokalisasi (`NotificationService`, `ExportService`, `BackupService`)**: Notifikasi lokal, laporan ekspor PDF/CSV, dan dialog backup menggunakan template string Bahasa Indonesia mentah tanpa memanfaatkan `easy_localization`.
5. **Beban Key Tidak Terrefrensi (Orphaned Keys)**: Dari 324 key di `en.json`, sebanyak 144 key (44.4%) tidak terdeteksi dipanggil di source code `.dart`.
6. **Korupsi Encoding Karakter (Mojibake)**: File JSON translasi mengalami korupsi encoding UTF-8 (double/triple encoding) untuk karakter emoji dan aksen non-ASCII, menyebabkan ukuran file membengkak (misal `es.json` membengkak hingga 30KB).

## Design Review
Arsitektur localization saat ini belum mematuhi *Clean Architecture* dan *Separation of Concerns*. Pemisahan antara *data ID (enum/key)* dan *presentation label* belum diterapkan. Modul bisnis bertindak sebagai penyedia teks UI, sementara formatters mengabaikan state locale global aplikasi.

---

# CRITICAL ISSUES

### CRIT-01: Korupsi Encoding Karakter UTF-8 (Mojibake) di File Translation JSON
- **Lokasi**: [assets/translations/](file:///e:/Nero/Spendly/assets/translations/) (`de.json`, `en.json`, `es.json`, `fr.json`, `hi.json`, `id.json`, `ja.json`, `ko.json`, `ms.json`, `pt.json`, `ru.json`, `vi.json`, `zh.json`)
- **Deskripsi**: Terjadi korupsi encoding UTF-8 berulang (mojibake). Karakter emoji dan huruf beraksen dikonversi menjadi urutan byte mentah seperti `Ãƒâ€šÃ‚Â°Ãƒâ€šÃ‚Â`.
- **Dampak**: Ukuran file membengkak hingga 200%, teks berpotensi tampil rusak pada device pengguna, dan merusak integritas data JSON.
- **Rekomendasi**: Lakukan decoding ulang file JSON ke UTF-8 murni (tanpa BOM) dan bersihkan karakter byte tambahan.
- **Evidence**: Pemindaian regex `r"Ã[ƒâ€Â†«©á­óúñÂ‚â„¢â€š‚]+"` menemukan 1,354 token korupsi di `es.json`, 296 di `de.json`, dan 131 di `en.json`. Ukuran file `es.json` tercatat 30,653 byte dibandingkan `en.json` 15,235 byte.
- **Method**: Analisis statis ukuran byte file dan ekstraksi pattern regex terhadap karakter UTF-8 terenkripsi ganda.
- **Limitation**: Analisis statis file tidak mensimulasikan rendering tampilan grafis pada berbagai versi Flutter engine atau OS tertentu.
- **Confidence**: High (Diverifikasi melalui pengukuran langsung pada struktur byte file JSON).

### CRIT-02: Reverse String-to-Key Lookup pada CategoryUtils
- **Lokasi**: [category_utils.dart:L37-L92](file:///e:/Nero/Spendly/lib/core/utils/category_utils.dart#L37-L92)
- **Deskripsi**: Map `_translationKeyMap` memetakan nama kategori Bahasa Indonesia mentah (`'Makanan & Minuman'`) ke key `cat_makanan_minuman`. Jika data tersimpan di DB dalam bahasa lain atau nama kustom, lookup bernilai `null` dan mengembalikan string mentah.
- **Dampak**: Kegagalan translasi untuk transaksi yang dibuat dari locale non-Indonesia atau sync antar perangkat.
- **Rekomendasi**: Simpan key kategori yang standar/immutable (misal `'food_drinks'`) di database, bukan string UI Bahasa Indonesia.
- **Evidence**: Struktur variabel `_translationKeyMap` di baris 37-92 terdefinisi secara eksplisit memetakan string Bahasa Indonesia sebagai Map Key.
- **Method**: Analisis statis AST dan pemeriksaan langsung kode sumber `category_utils.dart`.
- **Limitation**: Analisis statis tidak mengeksekusi query database SQLite/Drift secara runtime pada perangkat.
- **Confidence**: High (Diverifikasi dari definisi kode sumber).

### CRIT-03: Domain Layer Menghasilkan Teks Bahasa Indonesia Mentah
- **Lokasi**: [insight_engine.dart:L40-L100](file:///e:/Nero/Spendly/lib/features/insight/domain/services/insight_engine.dart#L40-L100), [ocr_parser_service.dart:L70-L95](file:///e:/Nero/Spendly/lib/features/scanner/domain/services/ocr_parser_service.dart#L70-L95)
- **Deskripsi**: `InsightEngine` membangun kalimat insight finansial langsung dalam Bahasa Indonesia (`'$pct% pengeluaran bulan ini...'`, `'Pengeluaran naik ${pct}%...'`) dan mengembalikannya pada `InsightData.message`. `OcrParserService` mengembalikan rekomendasi kategori dan pesan error parsing dalam Bahasa Indonesia.
- **Dampak**: UI tidak dapat merender insight atau hasil OCR dalam bahasa lain sekalipun locale aplikasi diubah.
- **Rekomendasi**: Kembalikan enum/type dan parameter terstruktur dari domain layer; lakukan penyusunan kalimat terjemahan di presentation layer menggunakan `tr()`.
- **Evidence**: String templat kalimat Bahasa Indonesia teridentifikasi langsung dalam method `generateInsights()` dan `suggestCategory()`.
- **Method**: Analisis statis alur pengembalian tipe data dari domain service.
- **Limitation**: Mengasumsikan objek `InsightData` dan hasil OCR dikonsumsi langsung oleh UI tanpa transformer layer terpisah.
- **Confidence**: High (Diverifikasi dari tipe kembalian method domain).

### CRIT-04: Hardcoded Locale 'id' dan Relative Dates pada DateFormatter
- **Lokasi**: [date_formatter.dart:L20-L42](file:///e:/Nero/Spendly/lib/core/utils/date_formatter.dart#L20-L42)
- **Deskripsi**: `DateFormatter` mengunci instansiasi `DateFormat` pada locale `'id'` (`DateFormat('dd MMM yyyy', 'id')`) dan mengembalikan string relatif `'Hari ini'` & `'Kemarin'`.
- **Dampak**: Format tanggal di seluruh aplikasi akan selalu berbahasa Indonesia terlepas dari bahasa yang dipilih pengguna.
- **Rekomendasi**: Gunakan `context.locale.languageCode` atau `EasyLocalization` active locale secara dinamis, serta gunakan key translasi untuk `'Hari ini'` dan `'Kemarin'`.
- **Evidence**: Kode baris 20-22 mendefinisikan static getter `DateFormat('...', 'id')` dan baris 40-41 mengembalikan literal `'Hari ini'` dan `'Kemarin'`.
- **Method**: Pemeriksaan statis terhadap definisi getter dan klausa pengondisian tanggal pada `date_formatter.dart`.
- **Limitation**: Tidak mendeteksi jika terdapat override dinamis melalui mekanisme intl global di luar file ini.
- **Confidence**: High (Diverifikasi dari kode sumber kelas `DateFormatter`).

### CRIT-05: Hardcoded Locale 'id_ID' dan Simbol 'Rp' pada CurrencyFormatter
- **Lokasi**: [currency_formatter.dart:L6-L11](file:///e:/Nero/Spendly/lib/core/utils/currency_formatter.dart#L6-L11)
- **Deskripsi**: `CurrencyFormatter` mengunci format ke `locale: 'id_ID'` dan `symbol: 'Rp '`.
- **Dampak**: Tidak mendukung multi-mata uang atau format ribuan/desimal sesuai standar negara lain (misal USD `$1,234.56` vs IDR `Rp 1.234,56`).
- **Rekomendasi**: Integrasikan format angka/mata uang dengan locale aktif aplikasi atau user preference currency.
- **Evidence**: Baris 6 dan 9 memuat instansiasi `NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ')`.
- **Method**: Analisis statis variabel konstan pada `currency_formatter.dart`.
- **Limitation**: Pengujian tidak mengukur apakah ada pengaturan simbol mata uang tambahan pada SharedPreferences yang di-inject runtime.
- **Confidence**: High (Diverifikasi dari deklarasi kode statis).

---

# HIGH ISSUES

### HIGH-01: Notifikasi Lokal & Background Menggunakan Bahasa Indonesia Hardcoded
- **Lokasi**: [notification_service.dart:L19-L32, L134-L155, L190-L234](file:///e:/Nero/Spendly/lib/core/services/notification_service.dart#L19-L32)
- **Deskripsi**: `inactivityMessages` berisi 12 pesan pengingat hardcoded Indonesia. Notifikasi batas budget, goal achieved, dan transaksi berulang semuanya dikirim dalam string Bahasa Indonesia mentah.
- **Rekomendasi**: Terjemahkan notifikasi sebelum dikirim atau gunakan key localization yang disesuaikan dengan locale sistem.
- **Evidence**: Array `inactivityMessages` (baris 19-32) dan method `showNotification` memuat literal string Bahasa Indonesia mentah.
- **Method**: Analisis statis kode sumber `notification_service.dart`.
- **Limitation**: Analisis statis tidak menangkap payload notifikasi push jarak jauh (remote FCM) yang dikirim dari server/console.
- **Confidence**: High (Untuk notifikasi lokal terjadwal yang didefinisikan dalam kode).

### HIGH-02: Ekspor PDF & CSV Menggunakan Header dan Ringkasan Hardcoded
- **Lokasi**: [export_service.dart:L23-L31, L65-L154](file:///e:/Nero/Spendly/lib/features/export/domain/services/export_service.dart#L23-L31)
- **Deskripsi**: Header kolom CSV/PDF (`'Tanggal'`, `'Tipe'`, `'Kategori'`, `'Nominal'`, `'Catatan'`) serta ringkasan PDF (`'Spendly — Laporan Keuangan'`, `'Pemasukan'`, `'Pengeluaran'`, `'Tabungan'`) ditulis hardcoded dalam Bahasa Indonesia.
- **Rekomendasi**: Operkan parameter `BuildContext` atau string terisolasi yang sudah diterjemahkan via `.tr()` ke `ExportService`.
- **Evidence**: Array header CSV di baris 23 dan widget builder PDF di baris 65-154 memuat string Bahasa Indonesia mentah.
- **Method**: Analisis statis terhadap method `exportToCsv` dan `exportToPdf`.
- **Limitation**: Pemeriksaan tidak membuka dokumen binary PDF hasil ekspor pada media penyimpanan fisik.
- **Confidence**: High (Diverifikasi langsung pada kode pembentuk dokumen).

### HIGH-03: Kategori dan Nama Hari Hardcoded pada AppConstants
- **Lokasi**: [app_constants.dart:L9-L78](file:///e:/Nero/Spendly/lib/core/constants/app_constants.dart#L9-L78)
- **Deskripsi**: 53 nama kategori pengeluaran/pemasukan serta nama hari (`['Senin', 'Selasa', ...]`) didefinisikan sebagai string konstanta Bahasa Indonesia mentah.
- **Rekomendasi**: Konversi daftar kategori menjadi daftar enum/ID terstandarisasi.
- **Evidence**: Deklarasi `List<String> expenseCategories`, `incomeCategories`, `daysOfWeek`, dan `daysOfWeekFull` pada baris 9-78.
- **Method**: Inspeksi langsung struktur konstanta pada `app_constants.dart`.
- **Limitation**: Pengujian statis tidak mengukur frekuensi pemanggilan variabel konstanta ini oleh komponen UI eksternal.
- **Confidence**: High (Diverifikasi dari kode sumber).

### HIGH-04: Component/Shared Widgets Mengandung Teks Hardcoded
- **Lokasi**: [date_range_picker.dart:L45-L74](file:///e:/Nero/Spendly/lib/shared/widgets/date_range_picker.dart#L45-L74), [coach_mark.dart](file:///e:/Nero/Spendly/lib/shared/widgets/coach_mark.dart), [empty_state.dart](file:///e:/Nero/Spendly/lib/shared/widgets/empty_state.dart)
- **Deskripsi**: Preset tanggal (`'Minggu ini'`, `'Bulan ini'`, `'3 Bulan Terakhir'`), tombol instruksi coach mark, dan empty state mengandung string Bahasa Indonesia hardcoded.
- **Rekomendasi**: Ekstrak seluruh string widget bersama ke file translation JSON.
- **Evidence**: Deklarasi array `_presets` pada `date_range_picker.dart#L45-L74` memuat string Bahasa Indonesia.
- **Method**: Analisis statis komponen shared widget.
- **Limitation**: Terbatas pada widget yang berada di bawah folder `lib/shared/widgets/`.
- **Confidence**: High (Diverifikasi pada kode sumber widget).

### HIGH-05: 144 Key Translation Tidak Terrefrensi (Orphaned / Unused Keys)
- **Lokasi**: [assets/translations/en.json](file:///e:/Nero/Spendly/assets/translations/en.json)
- **Deskripsi**: 144 dari 324 key (44.4%) tidak terdeteksi dipanggil oleh `.tr()` di mana pun dalam kode `.dart`.
- **Rekomendasi**: Bersihkan key mati atau hubungkan ke UI widget yang sesuai.
- **Evidence**: Hasil pencocokan silang antara key JSON `en.json` dan panggilan `.tr()` di seluruh 139 file `.dart`.
- **Method**: Script pencocokan statis string key antara file JSON translasi dan pemanggilan `.tr()` / `tr()` pada kode sumber.
- **Limitation**: Analisis statis berbasis string mungkin tidak mendeteksi jika key disusun secara dinamis melalui penggabungan string (misal `'prefix_' + variable`).
- **Confidence**: Moderate-High (Berdasarkan pencocokan statis string literal).

### HIGH-06: Inisialisasi Date Formatting Hanya untuk 'id' di Main.dart
- **Lokasi**: [main.dart:L23](file:///e:/Nero/Spendly/lib/main.dart#L23)
- **Deskripsi**: `await initializeDateFormatting('id', null);` hanya menginisialisasi locale `'id'`. Jika locale diubah ke `'en'`, `'es'`, dll., pemanggilan `DateFormat` dapat mengalami fallback tidak terduga.
- **Rekomendasi**: Panggil `initializeDateFormatting(null, null)` untuk menginisialisasi seluruh locale yang didukung.
- **Evidence**: Kode baris 23 pada `main.dart` memuat argumen tunggal `'id'`.
- **Method**: Analisis statis file entrypoint `main.dart`.
- **Limitation**: Pengujian tidak mengeksekusi simulasi runtime perantian locale pada intl package.
- **Confidence**: High (Diverifikasi dari parameter pemanggilan fungsi).

---

# MEDIUM ISSUES

### MED-01: Ketidakstabilan Konvensi Naming Key Translation
- **Deskripsi**: Penamaan key mencampurkan awalan domain (`cat_`, `notif_`, `pdf_`, `dialog_`) dengan key umum tanpa awalan (`income`, `expense`, `save`, `cancel`, `search`).
- **Rekomendasi**: Terapkan hierarki key terspesifikasi (contoh: `common.buttons.save`, `features.budget.title`).

### MED-02: 500+ String UI Hardcoded pada Layar Utama Aplikasi
- **Deskripsi**: Terdeteksi 500+ string UI hardcoded di layar `SettingsScreen` (50), `TransactionDetailScreen` (39), `LoginScreen` (38), `ExportScreen` (38), `RecurringScreen` (30), `ScannerScreen` (27), `AnalyticsScreen` (23), `NotificationScreen` (22), `OnboardingScreen` (21), `BudgetHistoryScreen` (20).
- **Rekomendasi**: Bungkus seluruh teks UI dengan `.tr()` dan daftarkan ke file JSON.

### MED-03: Pemasangan UI Widget dalam Service File (`BackupService`)
- **Deskripsi**: [backup_service.dart:L250-L350](file:///e:/Nero/Spendly/lib/features/settings/domain/services/backup_service.dart#L250-L350) menyatukan logika service backup dengan modal bottom sheet UI `BackupRestoreSheet` yang dipenuhi string hardcoded.
- **Rekomendasi**: Pisahkan widget UI ke folder `presentation/widgets` dan murnikan service layer.

---

# LOW ISSUES

### LOW-01: Tidak Ada Tool Automation / CI Quality Gate untuk Localization
- **Deskripsi**: Belum ada script penguji atau linting otomatis yang mencegah developer menambahkan string hardcoded baru ke UI.
- **Rekomendasi**: Tambahkan linter rule atau CI check script.

### LOW-02: Kurangnya Handling Dynamic Fallback untuk Input Kategori Kustom
- **Deskripsi**: Jika pengguna membuat kategori kustom, aplikasi belum memiliki penanganan fallback simbol/nama yang konsisten saat berganti bahasa.
- **Rekomendasi**: Berikan penanda visual/flag untuk kategori bawaan vs kategori kustom pengguna.

---

# HARDCODED USER VISIBLE STRINGS

| File | Line | Text | Severity | Recommendation |
|---|---|---|---|---|
| [app_constants.dart](file:///e:/Nero/Spendly/lib/core/constants/app_constants.dart#L10) | L10 | `Makanan & Minuman` | Medium | Bungkus dengan `.tr()` dan tambahkan ke `assets/translations/*.json` |
| [app_constants.dart](file:///e:/Nero/Spendly/lib/core/constants/app_constants.dart#L11) | L11 | `Transportasi` | Medium | Bungkus dengan `.tr()` dan tambahkan ke `assets/translations/*.json` |
| [app_constants.dart](file:///e:/Nero/Spendly/lib/core/constants/app_constants.dart#L12) | L12 | `Bahan Bakar` | Medium | Bungkus dengan `.tr()` dan tambahkan ke `assets/translations/*.json` |
| [app_constants.dart](file:///e:/Nero/Spendly/lib/core/constants/app_constants.dart#L13) | L13 | `Belanja` | Medium | Bungkus dengan `.tr()` dan tambahkan ke `assets/translations/*.json` |
| [app_constants.dart](file:///e:/Nero/Spendly/lib/core/constants/app_constants.dart#L14) | L14 | `Hiburan` | Medium | Bungkus dengan `.tr()` dan tambahkan ke `assets/translations/*.json` |
| [app_constants.dart](file:///e:/Nero/Spendly/lib/core/constants/app_constants.dart#L15) | L15 | `Kesehatan` | Medium | Bungkus dengan `.tr()` dan tambahkan ke `assets/translations/*.json` |
| [app_constants.dart](file:///e:/Nero/Spendly/lib/core/constants/app_constants.dart#L16) | L16 | `Tagihan & Utilitas` | Medium | Bungkus dengan `.tr()` dan tambahkan ke `assets/translations/*.json` |
| [notification_service.dart](file:///e:/Nero/Spendly/lib/core/services/notification_service.dart#L20) | L20 | `Dompet kamu kangen disentuh nih! 💸 Sudah catat pengeluaran hari ini?` | Medium | Bungkus dengan `.tr()` dan tambahkan ke `assets/translations/*.json` |
| [notification_service.dart](file:///e:/Nero/Spendly/lib/core/services/notification_service.dart#L134) | L134 | `Peringatan Anggaran ⚠️` | Medium | Bungkus dengan `.tr()` dan tambahkan ke `assets/translations/*.json` |
| [notification_service.dart](file:///e:/Nero/Spendly/lib/core/services/notification_service.dart#L153) | L153 | `Target Tercapai! 🎉` | High | Bungkus dengan `.tr()` dan tambahkan ke `assets/translations/*.json` |

*(Berdasarkan analisis statis, terdeteksi 1,213 kemunculan string user-visible hardcoded pada 78 file `.dart`)*

---

# NEEDS REVIEW

Berikut adalah string yang memerlukan verifikasi tingkat lanjut apakah ditampilkan ke pengguna dalam antarmuka UI:
- **Exception & Log Messages di Service Layer**: String exception pada `AuthServiceFirebase` (*'User not logged in'*), `RestoreService` (*'Restore failed'*), `SyncService` (*'Sync connection failed'*). Jika ditangkap oleh `catch` block dan ditampilkan ke UI via SnackBar, perlu dialihkan ke key terjemahan.
- **Fallback String pada Data Model**: Model `ScannedTransactionResult` yang mengembalikan `'Unknown Merchant'` atau `'Date not detected'` saat OCR gagal.

---

# INTERNAL STRINGS

String internal berikut **sengaja tidak perlu diterjemahkan** berdasarkan evaluasi statis:
- **Route Names**: `'/login'`, `'/dashboard'`, `'/analytics'`, `'/budget'`, `'/goals'`, `'/settings'`, `'/profile'`, `'/transactions'`, `'/scanner'`, `'/recurring'`, `'/wallet'`
- **Database Column & Table Keys**: `'transactions'`, `'wallets'`, `'budgets'`, `'goals'`, `'user_id'`, `'created_at'`, `'updated_at'`, `'amount'`, `'category'`, `'note'`, `'type'`
- **Firestore Collections & Storage Keys**: `'users'`, `'user_data'`, `'last_backup_date'`, `'theme_mode'`, `'security_pin'`
- **Channel & Package IDs**: `'spendly_channel'`, `'spendly_recurring_channel'`, `'com.example.spendly'`, `'assets/images/logo.png'`
- **MIME Types & Formatting Codes**: `'application/json'`, `'text/csv'`, `'#121212'`, `'#FFFFFF'`, `'yyyy-MM-dd'`

---

# MISSING TRANSLATION KEYS

- **Status**: Berdasarkan analisis pemanggilan statis, terdeteksi 0 missing key dari pemanggilan `.tr()` yang ada saat ini. Pemanggilan `.tr()` yang sudah ada seluruhnya terdaftar di `en.json`.
- **Catatan**: 1,213 string hardcoded yang belum memiliki key perlu dibuatkan key baru pada fase perbaikan.

---

# UNUSED TRANSLATION KEYS

Berdasarkan analisis static matching, 144 key (44.4% dari total 324 key) di `assets/translations/en.json` tidak terdeteksi dipanggil oleh `.tr()` di kode `.dart`. Beberapa contoh:
- `empty_transactions_sub_alt`
- `manage_and`
- `delete_goal_sub`
- `goal_achieved_status`
- `deadline_overdue`
- `achieved_percent`
- `need_per_day`
- `per_day`

---

# DUPLICATE KEYS

- Tidak ditemukan duplicate key secara sintaksis JSON (karena JSON parser menimpa key identik).
- Terdapat duplikasi makna/value pada key berbeda, contoh: `save` vs `save_now` vs `save_goal` vs `save_wallet` vs `save_changes` vs `confirm_save`.

---

# INCONSISTENT NAMING

- Struktur key bersifat **flat (1 tingkat)** dengan pemisahan underscore `_`.
- Terjadi ketidakselarasan penamaan prefix: `cat_` untuk 53 kategori, `day_` untuk 14 nama hari, `notif_` untuk 10 notifikasi, `pdf_` untuk 4 ekspor PDF, namun fitur lain menggunakan nama langsung seperti `monthly_budget`, `financial_goals`, `scanner_review`.

---

# DYNAMIC LOCALIZATION RISKS

1. **Struktur Kalimat Interpolasi Terikat Tata Bahasa Indonesia**:
   - Contoh pada `InsightEngine`: `'$pct% pengeluaran bulan ini berasal dari kategori ${top.key}'`.
   - Pada bahasa dengan struktur kalimat berbeda (seperti Jepang atau Jerman), posisi variabel angka dan objek kategori berada di posisi berbeda. Penggabungan string secara langsung berisiko merusak tata bahasa.
2. **Format Angka & Mata Uang Keras**:
   - `CurrencyFormatter.format()` merender `Rp 100.000`. Jika pengguna memilih bahasa Inggris atau mata uang USD, penulisan tetap `Rp 100.000` bukannya `$100,000`.

---

# NOTIFICATION REVIEW

- **Status Audit**: **FAIL (TIDAK TERLOKALISASI)**
- **Temuan**: [notification_service.dart](file:///e:/Nero/Spendly/lib/core/services/notification_service.dart) tidak memiliki konteks `EasyLocalization` atau `BuildContext`. Notifikasi keaktifan, notifikasi budget (80% & 100%), selebrasi target, dan pengingat transaksi berulang dikirim dalam Bahasa Indonesia hardcoded.

---

# EXPORT REVIEW

- **Status Audit**: **FAIL (TIDAK TERLOKALISASI)**
- **Temuan**: [export_service.dart](file:///e:/Nero/Spendly/lib/features/export/domain/services/export_service.dart) merender dokumen PDF dan CSV dengan teks Bahasa Indonesia mentah (`'Spendly — Laporan Keuangan'`, `'Pemasukan'`, `'Pengeluaran'`, `'Tabungan'`, header tabel `'Tanggal'`, `'Tipe'`, `'Kategori'`, `'Nominal'`, `'Catatan'`).

---

# BACKGROUND SERVICE REVIEW

- **Status Audit**: **FAIL (TIDAK TERLOKALISASI)**
- **Temuan**: Background task FCM tidak melakukan inisialisasi `EasyLocalization` atau penyelarasan locale instance saat berjalan terpisah dari UI thread.

---

# SHARED WIDGET REVIEW

- **Status Audit**: **PARTIAL / NEEDS REFACTORING**
- **Temuan**: Component `SpendlyDateRangePicker` mengunci preset teks dalam Bahasa Indonesia (`'Minggu ini'`, `'Bulan ini'`, `'3 Bulan Terakhir'`). Component `CoachMark` dan `EmptyState` sebagian belum terhubung ke key translasi.

---

# FUTURE MAINTAINABILITY REVIEW

1. **Skalabilitas Aplikasi (2x lipat)**: Tanpa pembenahan arsitektur, penambahan screen atau fitur baru akan menambah string hardcoded baru per modul.
2. **Penambahan Bahasa Baru**: Penambahan bahasa ke-14 membutuhkan usaha manual besar karena mayoritas teks UI berada di kode `.dart` bukan di file JSON.
3. **Rekomendasi Otomasi**: Terapkan generator type-safe localization (`easy_localization_loader` atau `slang` / `flutter_gen`) serta CI linter check (`flutter analyze` dengan custom rule untuk hardcoded string).

---

# RECOMMENDED IMPROVEMENT ROADMAP

### Phase 1: Emergency Hotfix & Data Cleanup (Immediate)
1. **Perbaiki Korupsi Encoding UTF-8 (Mojibake)** pada 13 file JSON translasi di `assets/translations/`.
2. **Perbaiki Inisialisasi Date Formatting** di [main.dart](file:///e:/Nero/Spendly/lib/main.dart#L23) agar mendukung seluruh locale (`initializeDateFormatting(null, null)`).
3. **Bersihkan 144 Key Tidak Terrefrensi (Orphaned Keys)** dari file JSON translasi.

### Phase 2: Architecture Refactoring (Core & Domain Layer)
1. **Refactor `CategoryUtils`**: Ubah sistem simpan/lookup kategori dari string Indonesia mentah menjadi ID kategori terstandarisasi (`food_drinks`, `salary`, `transport`, dll.).
2. **Refactor `DateFormatter` & `CurrencyFormatter`**: Hubungkan formatters ke `Locale` aktif aplikasi secara dinamis.
3. **Refactor Domain Layer (`InsightEngine`, `OcrParserService`)**: Ubah keluaran domain layer menjadi enum/data struktur terisolasi, pisahkan penyusunan teks terjemahan ke presentation layer.
4. **Refactor Services (`NotificationService`, `ExportService`)**: Masukkan mekanisme penerjemahan berbasis locale aktif sebelum notifikasi dikirim atau laporan diekspor.

### Phase 3: Full UI String Extraction & Quality Gate Automation
1. **Ekstraksi String UI Hardcoded**: Pindahkan seluruh string dari file `.dart` ke file translation JSON dan bungkus dengan `.tr()`.
2. **Standardisasi Key Hierarchical Structure**: Rapikan penamaan key dengan struktur bernavigasi (`feature.screen.element`).
3. **Implementasi Linter CI & Type-Safe Code Generation**: Pasang automated check di CI pipeline untuk mencegah regresi string hardcoded baru di masa mendatang.

---

# FINAL CONCLUSION

Berdasarkan analisis statis menyeluruh, sistem localization project **Spendly** saat ini **BELUM SIAP PRODUCTION (NOT READY)** untuk penggunaan multi-bahasa enterprise.
Meskipun infrastruktur `easy_localization` sudah terpasang dan 13 file terjemahan telah disediakan, tingkat ketercakapan localization berdasarkan pengukuran statis berada di angka **16.5%**. Lebih dari **83.5% teks antarmuka pengguna, notifikasi, ekspor laporan, dan logika insight finansial terikat pada string Bahasa Indonesia mentah**.
Selain itu, ditemukannya korupsi encoding UTF-8 (mojibake) pada file translasi JSON serta kendala arsitektur berupa pencemaran domain layer dan reverse string-to-key lookup pada `CategoryUtils` berpotensi menimbulkan kendala fungsional dan ketidaksesuaian tampilan saat berganti bahasa. Laporan audit ini menyajikan peta jalan perbaikan secara bertahap untuk membawa Spendly menuju standar kualitas production enterprise.