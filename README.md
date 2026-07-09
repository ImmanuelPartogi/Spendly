# Spendly

> Personal finance tracker — smart, fast, and beautiful.

Spendly is a cross-platform personal finance application built with Flutter. It helps users track transactions, manage wallets, set budgets, save toward goals, and gain insights into their spending patterns — all secured with Firebase Authentication and a local PIN lock.

---

## Features

- **Transaction Management** — Record income and expenses with categories, notes, and dates.
- **Multi-Wallet Support** — Track multiple accounts (cash, bank, e-wallet) with live balance updates.
- **Budgets** — Set monthly spending limits per category with real-time progress tracking.
- **Savings Goals** — Define financial goals and allocate funds toward them.
- **Recurring Transactions** — Automate repeating income/expenses.
- **Analytics & Insights** — Visualize spending by category, day, weekday, and month.
- **OCR Receipt Scanner** — Extract amounts from receipts using ML Kit text recognition.
- **PDF / CSV Export** — Export financial reports for external use.
- **Cloud Sync** — Securely sync data across devices via Firebase Firestore.
- **Security** — Firebase Auth + optional 6-digit local PIN (salted SHA-256 hash, stored in secure storage).
- **Backup & Restore** — Export and import all data as a JSON file.
- **Offline-First** — Full functionality without an internet connection; syncs when online.

---

## Tech Stack

| Layer | Technology |
|-------|-----------|
| **Framework** | Flutter `>=3.10.0`, Dart `>=3.6.0` |
| **State Management** | Riverpod 2.x |
| **Navigation** | GoRouter |
| **Local Database** | Drift (SQLite) |
| **Cloud Backend** | Firebase (Auth, Firestore, Messaging) |
| **Charts** | FL Chart |
| **OCR** | Google ML Kit Text Recognition |
| **Security** | flutter_secure_storage + crypto (SHA-256) |
| **Export** | PDF, CSV, share_plus |

---

## Prerequisites

1. **Flutter SDK** `>=3.10.0` (stable channel)
2. **Dart SDK** `>=3.6.0`
3. A Firebase project with Authentication and Firestore enabled
4. Platform-specific setup:
   - **Android:** Android Studio / Android SDK (minSdk per Firebase requirements)
   - **iOS:** Xcode 15+, CocoaPods
   - **Web/Desktop:** See [Flutter's desktop guide](https://docs.flutter.dev/platform-integration)

---

## Getting Started

### 1. Clone and install dependencies

```bash
git clone https://github.com/ImmanuelPartogi/Spendly.git
cd Spendly
flutter pub get
```

### 2. Configure Firebase

This project requires a Firebase project. Add your platform-specific Firebase configuration files:

- **Android:** `android/app/google-services.json`
- **iOS:** `ios/Runner/GoogleService-Info.plist`

> **⚠️ Security:** These files contain API keys and must **never** be committed to version control. They are listed in `.gitignore`. Use your CI/CD pipeline or a secure secrets manager to inject them during builds.

The Dart-level Firebase configuration is generated via `flutterfire configure`:

```bash
dart pub global activate flutterfire_cli
flutterfire configure
```

This generates `lib/firebase_options.dart`.

### 3. Generate Drift code

The database layer uses Drift code generation:

```bash
dart run build_runner build --delete-conflicting-outputs
```

### 4. Run the app

```bash
flutter run
```

---

## Available Commands

| Command | Description |
|---------|-------------|
| `flutter pub get` | Install dependencies |
| `flutter run` | Run the app in debug mode |
| `flutter build apk --release` | Build a release APK |
| `flutter build ios --release` | Build a release iOS app |
| `flutter build web --release` | Build a release web bundle |
| `flutter test` | Run unit and widget tests |
| `flutter analyze` | Run static analysis and lint checks |
| `dart run build_runner build --delete-conflicting-outputs` | Generate Drift/Riverpod code |
| `dart run flutter_native_splash:create` | Generate splash screens |

---

## Environment Variables

Spendly does not use runtime environment variables directly. Firebase configuration is injected via generated code and platform config files.

| Variable / File | Purpose | Required |
|----------------|---------|----------|
| `android/app/google-services.json` | Firebase config (Android) | Yes (Android) |
| `ios/Runner/GoogleService-Info.plist` | Firebase config (iOS) | Yes (iOS) |
| `lib/firebase_options.dart` | Dart-level Firebase options (generated) | Yes |
| Android signing keystore (`*.jks` + `key.properties`) | Release build signing | Yes (release) |

> **⚠️ Never commit secrets.** Keystores, `key.properties`, and Firebase config files are in `.gitignore`.

---

## Project Structure

```
lib/
├── main.dart                      # App entry point & initialization
├── firebase_options.dart          # Generated Firebase config (do not edit manually)
├── core/                          # App-wide infrastructure
│   ├── database/                  # Drift database, DAOs, generated code
│   ├── providers.dart             # Riverpod dependency graph (single source)
│   ├── services/                  # SyncService, RestoreService
│   ├── theme/                     # AppTheme, AppColors, design tokens
│   └── router/                    # GoRouter route definitions
├── features/                      # Feature modules (clean architecture)
│   ├── auth/                      # Firebase Auth + local PIN
│   ├── transactions/              # Transaction CRUD, entities, models
│   ├── wallet/                    # Wallet management
│   ├── budget/                    # Budget tracking
│   ├── goals/                     # Savings goals
│   ├── recurring/                 # Recurring transactions
│   ├── insight/                   # Analytics & insights engine
│   ├── settings/                  # App settings, backup/restore
│   ├── home/                      # Dashboard & bottom navigation
│   └── analytics/                 # Detailed analytics screens
└── shared/                        # Shared widgets & utilities
    └── widgets/                   # Reusable UI components
```

### Architecture

Each feature follows a **clean architecture** pattern:

```
feature/
├── data/          # Data layer (repositories, models, DAOs)
├── domain/        # Business logic (entities, use cases, repository interfaces)
└── presentation/  # UI layer (screens, widgets)
```

- **Data flows down:** UI → Use Case → Repository → DAO → SQLite
- **Events flow up:** SQLite (Drift streams) → Repository → Riverpod providers → UI
- **Wallet balances** are updated atomically inside DAO write operations to prevent inconsistency.

---

## Testing

```bash
flutter test
```

Tests cover domain entities, immutability contracts, and business logic. Run static analysis before submitting PRs:

```bash
flutter analyze
```

---

## Contributing

1. Create a feature branch: `git checkout -b feat/your-feature`
2. Follow the existing code style — `flutter analyze` must pass with zero warnings.
3. Add tests for new business logic.
4. Ensure `dart run build_runner build --delete-conflicting-outputs` succeeds if you modify database schemas.
5. Submit a pull request with a clear description of the change.

### Coding Standards

- **Linting:** Strict rules enforced via `analysis_options.yaml` (strict-casts, strict-inference, prefer_const, require_trailing_commas, and more).
- **Imports:** Use relative imports within the project (`prefer_relative_imports`).
- **Immutability:** All entities extend `Equatable` and are immutable. Never mutate entity fields directly.
- **Error handling:** Never swallow exceptions silently (`empty_catches` is an error).
- **State management:** Use Riverpod providers defined in `lib/core/providers.dart`.

---

## Security

- **PIN Authentication:** The local PIN is stored as a **salted SHA-256 hash** in `flutter_secure_storage` (Android Keystore / iOS Keychain). The plaintext PIN is never persisted or transmitted.
- **Secrets:** Keystores, API keys, and Firebase config files are excluded from version control via `.gitignore`.
- **Cloud Sync:** Data is synced to the authenticated user's private Firestore document collection.

---

## Deployment

### Android (Release)

1. Generate or obtain your release keystore:
   ```bash
   keytool -genkey -v -keystore spendly-release.jks -keyalg RSA -keysize 2048 -validity 10000 -alias spendly
   ```
2. Create `android/key.properties` (gitignored):
   ```properties
   storePassword=*****
   keyPassword=*****
   keyAlias=spendly
   storeFile=../../spendly-release.jks
   ```
3. Build:
   ```bash
   flutter build apk --release
   ```

### iOS

1. Open `ios/Runner.xcworkspace` in Xcode.
2. Configure signing & capabilities.
3. Build:
   ```bash
   flutter build ipa --release
   ```

---

## License

This project is proprietary. All rights reserved.