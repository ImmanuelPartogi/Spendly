// ─────────────────────────────────────────────────────────────────────────────
// Barrel File — Providers Core & Features
// ─────────────────────────────────────────────────────────────────────────────
// Menyediakan re-export ke seluruh provider modular untuk mempertahankan
// backward-compatibility import pada komponen UI existing.
// ─────────────────────────────────────────────────────────────────────────────

export 'database/database_providers.dart';
export 'services/service_providers.dart';
export 'navigation/navigation_providers.dart';
export '../features/transactions/domain/providers/transaction_providers.dart';
export '../features/budget/domain/providers/budget_providers.dart';
export '../features/wallet/domain/providers/wallet_providers.dart';
export '../features/goals/domain/providers/goal_providers.dart';
export '../features/recurring/domain/providers/recurring_providers.dart';
export '../features/analytics/domain/providers/analytics_providers.dart';
export '../features/insight/domain/providers/insight_providers.dart';