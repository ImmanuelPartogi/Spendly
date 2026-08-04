# AGENT.md — Context & Guidelines for Spendly AI Assistants

---

## 1. Ringkasan Tujuan Project (Business Goal & Value)
- **Nama Aplikasi**: Spendly (Personal Finance Tracker — smart, fast, and beautiful).
- **Target User**: Individu yang ingin mencatat dan mengelola keuangan pribadi (pengeluaran, pemasukan, dompet, anggaran bulanan, target tabungan, dan transaksi berulang) dengan cepat, intuitif, serta didukung fitur otomatisasi OCR scanner.
- **Value Proposition**:
  - Offline-first dengan penyimpanan lokal super cepat via SQLite/Drift ORM.
  - Automatic receipt/payslip OCR scanning menggunakan Google ML Kit untuk ekstraksi data tanpa input manual yang rumit.
  - Multi-wallet & transfer dana antar dompet.
  - Visualisasi grafik analitik, manajemen anggaran (budget warning), target finansial (goals), dan transaksi berulang (recurring).
  - Sinkronisasi cloud dua arah (SQLite ↔ Cloud Firestore) dan restorasi data otomatis saat pengguna login via Firebase Auth.

---

## 2. Tech Stack Lengkap
- **Framework**: Flutter SDK (>=3.10.0, Dart SDK >=3.6.0 <4.0.0).
- **State Management**: Flutter Riverpod (`flutter_riverpod` ^2.5.1) — disetup secara manual tanpa code generation.
- **Local Database**: Drift ORM (`drift` ^2.18.0) dengan SQLite native bindings (`sqlite3_flutter_libs` ^0.5.24) & `path_provider`.
- **OCR Engine**: Google ML Kit Text Recognition (`google_mlkit_text_recognition` ^0.13.0) + `image_picker`.
- **Backend & Cloud Sync**: Firebase Core (^4.6.0), Firebase Auth (^6.3.0), Cloud Firestore (^6.2.0), Firebase Messaging (^16.1.3).
- **Export & Report**: `pdf` (^3.11.1), `printing` (^5.12.0), `csv` (^6.0.0), `share_plus` (^12.0.2).
- **UI & Analytics Visualization**: `fl_chart` (^0.68.0), `google_fonts` (^6.2.1), Material 3 design system.
- **Notifications**: `flutter_local_notifications` (^17.2.2).
- **Home Widget**: `home_widget` (^0.6.0).
- **Security & Storage**: `flutter_secure_storage` (^9.0.0), `crypto` (^3.0.3).

---

## 3. Peta Struktur Folder AKTUAL Project
```
Spendly/
├── android/
│   ├── app/ (build.gradle.kts, AndroidManifest.xml, google-services.json)
│   ├── build.gradle.kts
│   └── key.properties (Git-ignored local credentials)
├── assets/
│   └── images/ (logo.png)
├── lib/
│   ├── core/
│   │   ├── auth/ (auth_provider.dart)
│   │   ├── constants/ (app_constants.dart)
│   │   ├── database/ (app_database.dart, daos/)
│   │   ├── navigation/ (main_navigation.dart)
│   │   ├── services/ (auth_service_firebase.dart, sync_service.dart, restore_service.dart, notification_service.dart)
│   │   ├── theme/ (app_theme.dart, app_colors.dart, app_spacing.dart, theme_provider.dart)
│   │   ├── utils/ (category_utils.dart, currency_formatter.dart, date_formatter.dart, etc.)
│   │   └── providers.dart (Monolithic central Riverpod providers)
│   ├── features/
│   │   ├── analytics/ (presentation/ [screens, widgets])
│   │   ├── auth/ (domain/ [services], presentation/ [screens])
│   │   ├── budget/ (data/, domain/, presentation/)
│   │   ├── dashboard/ (presentation/ [screens])
│   │   ├── export/ (domain/ [services], presentation/ [screens])
│   │   ├── goals/ (data/, domain/, presentation/)
│   │   ├── home_widget/ (home_widget_service.dart)
│   │   ├── insight/ (domain/ [services], presentation/ [screens])
│   │   ├── notification/ (data/, presentation/)
│   │   ├── onboarding/ (presentation/ [screens])
│   │   ├── profile/ (presentation/ [screens])
│   │   ├── recurring/ (data/, domain/, presentation/)
│   │   ├── scanner/ (domain/ [services, models], presentation/ [screens])
│   │   ├── settings/ (presentation/ [screens])
│   │   ├── splash/ (Folder kosong - technical debt)
│   │   ├── transactions/ (data/, domain/, presentation/)
│   │   └── wallet/ (data/, domain/, presentation/)
│   │   └── app_gate.dart
│   ├── shared/
│   │   └── widgets/ (coach_mark.dart, custom buttons, empty states)
│   ├── firebase_options.dart
│   └── main.dart
├── test/
│   └── widget_test.dart
└── pubspec.yaml
```

---

## 4. Konvensi Penamaan & Code Style
- **File Names**: Lowercase dengan underscore / snake_case (`add_transaction_screen.dart`, `category_utils.dart`).
- **Class Names**: PascalCase (`AddTransactionScreen`, `CategoryUtils`, `AppDatabase`).
- **Provider Names**: camelCase diakhiri dengan `Provider` (`transactionRepositoryProvider`, `monthlyTransactionsProvider`, `themeProvider`).
- **Entity & Models**: Class data yang immutabilitas-nya dijaga via `Equatable` (`TransactionEntity`, `BudgetEntity`).
- **DAOs**: PascalCase diakhiri `Dao` (`TransactionDao`, `WalletDao`, `BudgetDao`).
- **Localization / Language**: UI Bahasa Indonesia untuk label, error message, dan pesan notifikasi.

---

## 5. Matriks Arsitektur Modul & Keputusan "Thin-Layer"

Aplikasi Spendly mengombinasikan **Clean Architecture 3-Layer** pada modul data-intensi dan **Thin Presentation-Only Layer** pada modul agregator/read-only. **JANGAN merestrukturisasi modul Thin-Layer menjadi 3-layer Clean Architecture** karena memang didesain demikian untuk menghindari over-engineering.

| Modul Fitur | Arsitektur Scope | Keputusan & Batasan Arsitektural |
| :--- | :--- | :--- |
| **Transactions** | 3-Layer (`data`, `domain`, `presentation`) | Modul utama dengan CRUD, UseCases, Repositories, DAOs, dan Firestore sync. |
| **Budget** | 3-Layer (`data`, `domain`, `presentation`) | Manajemen batasan anggaran per kategori dengan UseCases dan DAOs. |
| **Wallet** | 3-Layer (`data`, `domain`, `presentation`) | Manajemen saldo dompet, tipe akun, dan transfer antar dompet. |
| **Goals** | 3-Layer (`data`, `domain`, `presentation`) | Manajemen target tabungan dan alokasi dana. |
| **Recurring** | 3-Layer (`data`, `domain`, `presentation`) | Transaksi rutin terjadwal (bulanan/mingguan). |
| **Scanner / OCR**| Presentation + Domain Services | Ekstraksi gambar via ML Kit & parsing regex di `OcrParserService`. |
| **Auth** | Presentation + Domain Service | Login, register, PIN lock, dan sync state session user. |
| **Dashboard** | **Thin Presentation-Only** | Aggregator UI yang mengombinasikan provider saldo, pengeluaran, & transaksi terbaru. **Cukup Presentation.** |
| **Analytics** | **Thin Presentation-Only** | Visualisasi grafik `fl_chart`. Kalkulasi tren ditarik langsung dari Riverpod providers. **Cukup Presentation.** |
| **Export** | **Thin Presentation + Service** | Pilihan format PDF/CSV. Logika render ditangani `ExportService`. **Cukup Presentation + Service.** |
| **Insight** | **Thin Presentation + Domain Service** | Visualisasi saran keuangan. Logika rule engine ada di `InsightEngine`. **Cukup Presentation + Service.** |
| **Settings** | **Thin Presentation-Only** | Pengaturan tema, toggle PIN, & info app. **Cukup Presentation.** |
| **Profile** | **Thin Presentation-Only** | Informasi akun user & statistik global. **Cukup Presentation.** |

### 📱 Standar Penanganan Edge-to-Edge & Safe Insets
1. **Layar Standar (Simple Layout)**: Menggunakan `SafeArea(child: ...)` pada Scaffold body (`GoalsScreen`, `ExportScreen`, `SearchScreen`, `PinScreen`).
2. **Layar Custom Scroll / Sliver Header**: Menggunakan insets dinamis `MediaQuery.of(context).padding.top` untuk padding `SliverAppBar` transparan dan `safeBottom = MediaQuery.of(context).padding.bottom` / `_kBottomPad` (108px) untuk bagian bawah (`DashboardScreen`, `BudgetScreen`, `TransactionsScreen`, `ProfileScreen`, `AnalyticsScreen`). Pola ini mencegah terpotongnya latar belakang header melandai sekaligus menjamin kepatuhan Android 15 (API 35) gesture navigation bar.

---

## 6. Ringkasan Skema Database Drift (SQLite)

Database dikelola menggunakan Drift ORM ([app_database.dart](file:///e:/Nero/Spendly/lib/core/database/app_database.dart)) dengan schema version `4` (Updated in Fase 1 with `@TableIndex` on `date`, `walletId`, `category`):

1. **`Users`**: `id` (PK AutoInc), `name`, `createdAt`.
2. **`Wallets`**: `id` (PK UUID), `name`, `balance`, `type`, `colorValue`, `isDefault`, `synced`, `createdAt`.
3. **`Transactions`**: `id` (PK UUID), `walletId` (FK, Indexed), `amount`, `type` (`expense`/`income`), `category` (Indexed), `note`, `date` (Indexed), `createdAt`, `synced`, `isLocked`.
4. **`Budgets`**: `id` (PK AutoInc), `category`, `limitAmount`, `period`, `synced`.
5. **`Insights`**: `id` (PK AutoInc), `type`, `message`, `createdAt`.
6. **`Goals`**: `id` (PK UUID), `title`, `emoji`, `targetAmount`, `currentAmount`, `deadline`, `colorValue`, `isCompleted`, `createdAt`, `synced`.
7. **`Recurrings`**: `id` (PK UUID), `title`, `amount`, `type`, `category`, `frequency`, `dayOfMonth`, `dayOfWeek`, `isActive`, `nextDue`, `note`.

---

## 7. Known Issues & Technical Debt Register (Risk-Based Status)

### 🚨 BREAKING / CRITICAL
1. ~~**Production Keystore & Plaintext Password di Git**~~ $\rightarrow$ ✅ **RESOLVED IN TRACK A**:
   - File `spendly-release.jks` & `android/key.properties` dihapus secara permanen dari seluruh riwayat komit Git menggunakan `git filter-repo`. Keystore rilis final `spendly-release-final.jks` telah di-generate ulang dengan password aman yang di-rotate, `.gitignore` diperbarui, dan riwayat yang telah dibersihkan di-force push ke remote repository (`GitHub`). Berhasil diverifikasi via `flutter run --release` pada device fisik Android.
2. ~~**Database SQLite Tanpa Indexing (Full Table Scan)**~~ $\rightarrow$ ✅ **RESOLVED IN FASE 1**:
   - Indexed `date`, `walletId`, dan `category` di tabel `Transactions` (schema v4 migration).
3. ~~**Infrastruktur Auth Dipanggil Langsung dari Presentation UI**~~ $\rightarrow$ ✅ **RESOLVED IN FASE 2**:
   - Memindahkan direct `FirebaseAuth.instance` calls dari `login_screen.dart` dan `profile_screen.dart` ke `AuthController` & `AuthUIState` Notifier.

### ⚠️ HIGH
1. ~~**Hardcoded Business Mapping di Screen OCR**~~ $\rightarrow$ ✅ **RESOLVED IN FASE 2**:
   - Memindahkan pemetaan keyword merchant dari `scan_review_screen.dart` ke `OcrParserService.suggestCategory()`.
2. ~~**Inkonsistensi Kategori Transaksi & Emoji**~~ $\rightarrow$ ✅ **RESOLVED IN FASE 3**:
   - Menambahkan 6 kategori pengeluaran & 4 kategori pemasukan di `AppConstants`, serta menyelaraskan `CategoryUtils` (`_iconMap`/`_colorMap`/`getShortLabel`) dan `InsightEngine` (`_categoryEmoji`).
3. ~~**Dead / Unused Dependencies di `pubspec.yaml`**~~ $\rightarrow$ ✅ **RESOLVED IN FASE 1**:
   - Package `go_router`, `riverpod_annotation`, `riverpod_generator`, `riverpod_lint`, dan `custom_lint` telah dihapus dari `pubspec.yaml`.
4. ~~**Data Transaksi Export Masih Dummy Empty List**~~ $\rightarrow$ ✅ **RESOLVED IN FASE 3**:
   - `export_screen.dart` telah disambungkan ke `transactionRepositoryProvider` dan menyaring data transaksi aktual berdasarkan filter periode.
5. ~~**Monolithic Riverpod Provider File**~~ $\rightarrow$ ✅ **RESOLVED IN FASE 1**:
   - `lib/core/providers.dart` (415 baris) telah dipecah menjadi 10 file provider modular per-fitur dan `providers.dart` dijadikan *barrel export file*.
6. ~~**Pengujian APK Release R8 Minification**~~ $\rightarrow$ ✅ **RESOLVED IN FASE 7**:
   - Berhasil di-build (`app-release.apk`, 108.3MB) & verifikasi runtime dilakukan secara manual oleh user pada device Android fisik (bukan emulator), mencakup skenario Drift DB, ML Kit OCR, dan Firebase Auth, dengan ADB logcat bersih dari reflection crash.
7. ~~**Integrasi UI String ke `AppStrings` (Sebagian Besar Layar Masih Hardcoded ID)**~~ $\rightarrow$ ✅ **RESOLVED IN FASE 7**:
   - Perluasan kamus `AppStrings` ke total 158 kunci UI dengan 100% key parity antara `id` dan `en`. Seluruh 8 layar utama (`dashboard_screen.dart`, `add_transaction_screen.dart`, `transactions_screen.dart`, `budget_screen.dart`, `goals_screen.dart`, `profile_screen.dart`, `analytics_screen.dart`, `scan_review_screen.dart`) beserta widget pendukungnya telah diselaraskan ke `AppStrings.get(...)`. Seluruh 40 unit test (termasuk loop assertion check `supportedKeys` non-empty untuk ID & EN) lolos 100%.
8. ~~**Native Edge-to-Edge Enforcer & Audit `SafeArea`**~~ $\rightarrow$ ✅ **RESOLVED IN FASE 7**:
   - Penambahan `WindowCompat.setDecorFitsSystemWindows(window, false)` di `MainActivity.kt`, `SafeArea` pada `GoalsScreen` & `ExportScreen`, serta dokumentasi standar arsitektur hybrid insets di Section 5 disetujui.

### 🎨 COSMETIC / LOW
1. ~~**Folder Kosong `lib/features/splash/`**~~ $\rightarrow$ ✅ **RESOLVED IN FASE 1**:
   - Folder kosong `lib/features/splash/` telah dihapus.
2. ~~**Unused Legacy Helper Methods di `ocr_service.dart`**~~ $\rightarrow$ ✅ **RESOLVED IN FASE 6**:
   - Method legacy (`extractTotal`, `extractDate`, `extractMerchant`) telah dibersihkan dari `ocr_service.dart`.
3. **Cakupan Test Suite 8B (Unit Test vs Widget Test)**:
   - File `add_transaction_test.dart`, `scan_review_flow_test.dart`, dan `budget_warning_test.dart` menguji logika bisnis entity, StateNotifier, dan OcrParserService (54 unit test passing 100%). Pengujian interaksi widget UI tingkat tinggi (`testWidgets` dengan gesture tap/input) tidak diimplementasikan dan ditangani secara manual oleh user pada device fisik.

---

## 8. Ringkasan Eksekusi Refactoring & Fitur Baru (Fase 1 - 7)

- ✅ **FASE 1**: SQLite indexing (schema v4), pembersihan dead dependencies (`go_router`, `riverpod_annotation`, dll), penghapusan folder `splash/`, dan modularisasi `providers.dart` menjadi 10 provider per-fitur.
- ✅ **FASE 2**: Auth Controller Notifier (`auth_controller.dart` & `auth_state.dart`), eliminasi direct Firebase SDK call di UI, dan pemindahan merchant category mapping ke `OcrParserService.suggestCategory()`.
- ✅ **FASE 3**: Master kategori transaksi diperbanyak (24 pengeluaran, 14 pemasukan), diselaraskan di `CategoryUtils` & `InsightEngine`, serta integrasi `export_screen.dart` ke data transaksi provider.
- ✅ **FASE 4**: Penambahan `workmanager` & `POST_NOTIFICATIONS`, pool 12 pesan inaktivitas ramah, format rekap mingguan, `NotificationPrefNotifier`, dan UI toggle switch di `settings_screen.dart`.
- ✅ **FASE 5**: Dictionary `AppStrings` (ID & EN), `localeProvider` StateNotifier, dan pengubah bahasa interaktif di `settings_screen.dart`.
- ✅ **FASE 6**: Penambahan `proguard-rules.pro` & konfigurasinya di `build.gradle.kts`, pengaktifan `edgeToEdge` SystemUiMode di `main.dart`, dan pembersihan legacy methods di `ocr_service.dart`.
- ✅ **FASE 7**: AOT Release build APK (108.3MB), upgrade `workmanager` v0.7.0, perluasan `AppStrings` ke 158 kunci (100% key parity ID & EN), integrasi penuh 8 layar utama, native `WindowCompat.setDecorFitsSystemWindows` di `MainActivity.kt`, dan `SafeArea` pada `GoalsScreen` & `ExportScreen`. Seluruh 40 unit test passing 100%!
- ✅ **FASE 8**: Pembuatan `README.md` berstandar produksi, penambahan 3 test suite baru (`add_transaction_test.dart`, `scan_review_flow_test.dart`, `budget_warning_test.dart`) & regresi `LocaleNotifier` (total 54 unit test passing 100%), dan setup otomatisasi GitHub Actions CI (`.github/workflows/ci.yml`).

---

## 8. Instruksi Eksplisit untuk AI Assistant di Sesi Berikutnya

> ✋ **PERHATIAN UNTUK AI ASSISTANT / AGENT**:
> 1. **JANGAN PERNAH melakukan full-scan seluruh repo (`lib/`, `android/`, `pubspec.yaml`, dsb) lagi pada sesi berikutnya.** Full scan PERTAMA dan TERAKHIR sudah selesai dilakukan di sesi audit awal.
> 2. **BACA FILE INI TERLEBIH DAHULU** untuk memahami konteks project, arsitektur, keputusannya, dan daftar isu yang ada.
> 3. **HANYA scan file atau folder yang relevan secara langsung dengan task yang diminta oleh user.**
> 4. **JANGAN mencoba merestrukturisasi modul Thin-Layer** (`Dashboard`, `Analytics`, `Export`, `Insight`, `Settings`, `Profile`) menjadi 3-layer Clean Architecture.
> 5. **UPDATE bagian yang relevan di file ini** setiap kali ada perubahan struktur, penambahan fitur, atau perbaikan refactoring yang signifikan.
