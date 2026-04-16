import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spendly/core/providers.dart';

import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'core/services/sync_service.dart';
import 'features/app_gate.dart';
import 'firebase_options.dart';

late ProviderContainer _container;
String? _activeUid;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

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

  FirebaseAuth.instance.authStateChanges().listen((user) async {
  if (user == null) { _activeUid = null; return; }

  final restore = _container.read(restoreServiceProvider);

  if (user.uid != _activeUid) {
    _activeUid = user.uid;
    // Tandai restore belum selesai
    _container.read(restoreReadyProvider.notifier).state = false;
    try {
      await restore.restoreFromFirebase();
    } catch (e) {
      debugPrint('[Main] Restore error: $e');
    }
    // Restore selesai — beri sinyal ke AppGate
    _container.read(restoreReadyProvider.notifier).state = true;
  } else {
    _container.read(restoreReadyProvider.notifier).state = true;
    try { await restore.recalculateBalances(); } catch (_) {}
  }
});

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
  ));
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