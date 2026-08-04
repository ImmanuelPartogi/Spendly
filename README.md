# Spendly — Smart, Fast, & Beautiful Personal Finance Tracker

Spendly is a modern, offline-first personal finance management application built with **Flutter**, **Riverpod**, **Drift (SQLite)**, and **Google ML Kit OCR**. It empowers users to track expenses, manage multi-currency/multi-wallet balances, monitor monthly budget limits, set savings goals, and automate receipt entry with smart OCR text extraction.

---

## 🌟 Key Features

- **⚡ Offline-First & Lightning Fast**: Local storage powered by **Drift (SQLite)** with multi-index query optimizations for instant load times and zero network latency.
- **📷 Smart OCR Receipt & Payslip Scanner**: On-device text recognition using **Google ML Kit** to automatically extract merchant names, document types (receipt/salary slip), amounts, dates, and category suggestions.
- **💼 Multi-Wallet & Fund Transfers**: Manage multiple accounts (Cash, Bank, E-Wallet, Credit) and transfer balances seamlessly.
- **📊 Interactive Analytics & Insights**: Visual financial breakdown charts using **FL Chart**, monthly comparisons, and automated saving rule calculations.
- **🎯 Budgeting & Warning Alerts**: Set monthly budget caps per category with visual warning indicators at $\ge 80\%$ limit usage.
- **🏆 Financial Goals & Savings**: Track progress toward long-term savings targets with automated deadline calculations.
- **🔄 Recurring Transactions**: Schedule automated income and expense entries (daily, weekly, monthly, yearly).
- **🌐 Dual Language Support (i18n)**: Instant runtime switching between **Bahasa Indonesia** and **English** powered by `AppStrings` and Riverpod state management.
- **☁️ Firebase Dual Cloud Backup**: Seamless background data sync to Cloud Firestore and account restoration via Firebase Auth.
- **🔒 PIN Security**: Optional app lock powered by local PIN authentication and Flutter Secure Storage.

---

## 🛠️ Tech Stack & Key Libraries

| Component | Library / Framework | Version |
| :--- | :--- | :--- |
| **Framework** | Flutter SDK (Dart 3.x) | `>=3.10.0` |
| **State Management** | Flutter Riverpod | `^2.5.1` |
| **Local Database** | Drift ORM (SQLite) | `^2.18.0` |
| **OCR Scanner** | Google ML Kit Text Recognition | `^0.13.0` |
| **Cloud Sync & Auth** | Firebase Core, Auth, Firestore | `^4.6.0` |
| **Charts & Visualization**| FL Chart | `^0.68.0` |
| **PDF & CSV Export** | PDF, Printing, CSV, Share Plus | `^3.11.1` |
| **Local Notifications** | Flutter Local Notifications | `^17.2.2` |
| **Background Tasks** | Workmanager | `^0.7.0` |
| **Secure Storage** | Flutter Secure Storage | `^9.0.0` |

---

## 🏗️ Architecture Overview

Spendly follows a pragmatic **Hybrid Architecture** tailored for scalable, maintainable Flutter development:

```
lib/
├── core/                         # Shared kernel & infrastructure
│   ├── auth/                     # Global Auth State & Controller
│   ├── database/                 # Drift SQLite Database Schema & DAOs
│   ├── localization/             # AppStrings (ID/EN) & LocaleProvider
│   ├── navigation/               # Main Navigation Bar & Shell
│   ├── services/                 # Firebase Sync, Restore, Notifications
│   └── theme/                    # App Colors, Typography & Theme Manager
└── features/                     # Feature Modules
    ├── analytics/                # Report generation & spending breakdown
    ├── auth/                     # Login & Anonymous authentication
    ├── budget/                   # Category budget limits & warnings
    ├── dashboard/                # Main dashboard summary & quick actions
    ├── export/                   # PDF & CSV transaction exporter
    ├── goals/                    # Savings goals & progress tracking
    ├── insight/                  # Rule-based financial insight engine
    ├── notification/             # Reminders & weekly recap notifications
    ├── profile/                  # Account management & app settings
    ├── recurring/                # Automated recurring transaction engine
    ├── scanner/                  # Google ML Kit OCR scanner & review sheet
    ├── transactions/             # Transaction CRUD, history & filtering
    └── wallet/                   # Multi-wallet & balance transfer
```

- **Domain Core Modules** (`Auth`, `Transactions`, `Wallet`, `Scanner`) utilize Clean Architecture sub-layers (`domain/`, `data/`, `presentation/`).
- **Thin Presentation Modules** (`Dashboard`, `Analytics`, `Export`, `Profile`) use direct Riverpod Provider consumption to prevent unnecessary boilerplate.

---

## 🚀 Local Setup & Development Guide

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (`>=3.10.0`)
- Android Studio / VS Code with Dart & Flutter plugins
- JDK 17 (OpenJDK) for Android build support

### Step 1: Clone Repository
```bash
git clone https://github.com/ImmanuelPartogi/Spendly.git
cd Spendly
```

### Step 2: Install Dependencies
```bash
flutter pub get
```

### Step 3: Local Keystore & Credentials Setup
> 🔒 **Security Notice**: Production keystores (`*.jks`) and `android/key.properties` are strictly Git-ignored.

To build and run the release APK locally:
1. Generate your local debug/release keystore:
   ```bash
   keytool -genkey -v -keystore android/app/spendly-release-final.jks \
     -keyalg RSA -keysize 2048 -validity 10000 -alias spendly
   ```
2. Create `android/key.properties` in your local working directory:
   ```ini
   storePassword=YOUR_STORE_PASSWORD
   keyPassword=YOUR_KEY_PASSWORD
   keyAlias=spendly
   storeFile=spendly-release-final.jks
   ```

### Step 4: Run the Application
```bash
# Debug Mode
flutter run

# Release Mode on Physical Device
flutter run --release
```

---

## 🧪 Testing & Code Quality

Spendly includes comprehensive automated unit, widget, and regression test coverage:

```bash
# Run all unit & widget tests
flutter test

# Run static code analysis
flutter analyze
```

### Test Coverage Highlights:
- **`localization_test.dart`**: Verifies dictionary completeness, non-empty key resolution, and 100% key parity across `id` and `en` locales.
- **`category_utils_test.dart`**: Ensures every expense and income category has valid icons, colors, and short labels.
- **`ocr_parser_service_test.dart`**: Tests smart category suggestions based on merchant keywords and document types.
- **`auth_controller_test.dart`**: Tests Firebase Auth state transitions and friendly error mapping.
- **`app_database_test.dart`**: Validates Drift SQLite schema version 4 and multi-column table indexes.

---

## 📦 Production Release & ProGuard/R8 Guide

Spendly is configured for AOT minification and code shrinking via **R8 / ProGuard**.

Rules in [`android/app/proguard-rules.pro`](file:///e:/Nero/Spendly/android/app/proguard-rules.pro) preserve essential reflection data for:
- Drift SQLite ORM & SQLite3 native C-bindings
- Google ML Kit Vision & Text Recognition APIs
- Firebase Core, Auth, Firestore & Cloud Messaging

To build a release APK bundle:
```bash
flutter build apk --release
```

Output APK will be generated at `build/app/outputs/flutter-apk/app-release.apk`.

---

## 📄 License

This project is maintained by **Immanuel Partogi**. Distributed under the MIT License.