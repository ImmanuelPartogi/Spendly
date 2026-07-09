import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart'; // ← tambah ini
import 'core/providers.dart';

import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'core/services/sync_service.dart';
import 'features/app_gate.dart';
import 'firebase_options.dart';

late ProviderContainer _container;
String? _activeUid;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await initializeDateFormatting('id', null); // ← tambah ini

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(statusBarColor: Colors.transparent),
  );
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('[Main] Firebase initialized');
  } catch (e) {
    debugPrint('[Main] Firebase unavailable: $e');
  }

  _container = ProviderContainer();

  // ── Auth state listener ───────────────────────────────────────────────────
  //
  // Saat user login → restore data dari Firebase (transaksi, wallet, budget)
  // PIN TIDAK di-restore dari sini karena PIN hanya ada di local storage.
  //
  FirebaseAuth.instance.authStateChanges().listen((user) async {
    if (user == null) {
      _activeUid = null;
      _container.read(restoreReadyProvider.notifier).state = false;
      return;
    }

    final restore = _container.read(restoreServiceProvider);

    if (user.uid != _activeUid) {
      _activeUid = user.uid;
      _container.read(restoreReadyProvider.notifier).state = false;
      try {
        await restore.restoreFromFirebase().timeout(
          const Duration(seconds: 5),
          onTimeout: () {
            debugPrint('[Main] Restore timeout — continuing with local cache');
          },
        );
        debugPrint('[Main] Restore complete for new user session');
      } catch (e) {
        debugPrint('[Main] Restore error: $e');
      }
      _container.read(restoreReadyProvider.notifier).state = true;
    } else {
      // Same UID (app restart / reconnect) — no full restore needed
      _container.read(restoreReadyProvider.notifier).state = true;
      try {
        await restore.recalculateBalances();
      } catch (e) {
        debugPrint('[Main] Balance recalculation error: $e');
      }
    }
  });

  // ── Sync pending saat online kembali ─────────────────────────────────────
  SyncService.onConnectivityChanged.listen((isOnline) async {
    if (!isOnline) return;
    try {
      final repo = _container.read(transactionRepositoryImplProvider);
      await repo.syncPending();
    } catch (e) {
      debugPrint('[Main] Sync error: $e');
    }
  });

  runApp(UncontrolledProviderScope(
    container: _container,
    child: const SpendlyApp(),
  ),);
}

class SpendlyApp extends ConsumerWidget {
  const SpendlyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    return MaterialApp(
      title: 'Spendly',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      home: const AppGate(),
    );
  }
}