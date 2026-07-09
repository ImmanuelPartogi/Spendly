import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'auth_service_firebase.dart';

class SyncService {
  static final _firestore    = FirebaseFirestore.instance;
  static final _connectivity = Connectivity();

  static Future<bool> get isOnline async {
    final result = await _connectivity.checkConnectivity();
    return result.contains(ConnectivityResult.wifi) ||
        result.contains(ConnectivityResult.mobile) ||
        result.contains(ConnectivityResult.ethernet);
  }

  static Stream<bool> get onConnectivityChanged =>
      _connectivity.onConnectivityChanged.map(
        (results) =>
            results.contains(ConnectivityResult.wifi) ||
            results.contains(ConnectivityResult.mobile) ||
            results.contains(ConnectivityResult.ethernet),
      );

  static CollectionReference<Map<String, dynamic>> _col(String name) {
    final uid = FirebaseAuthService.currentUserId;
    if (uid == null) throw Exception('User not logged in');
    return _firestore.collection('users').doc(uid).collection(name);
  }

  // ── TRANSACTIONS ──────────────────────────────────────────────────────────

  static Future<void> uploadTransaction(Map<String, dynamic> data) async {
    if (!await isOnline) return;
    try {
      await _col('transactions')
          .doc(data['id'] as String)
          .set(_sanitize(data), SetOptions(merge: true));
      debugPrint('[Sync] Transaction uploaded: ${data['id']}');
    } catch (e) {
      debugPrint('[Sync] Upload transaction error: $e');
    }
  }

  static Future<void> deleteTransaction(String id) async {
    if (!await isOnline) return;
    try {
      await _col('transactions').doc(id).update({
        'deleted':   true,
        'deletedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('[Sync] Delete transaction error: $e');
    }
  }

  static Future<List<Map<String, dynamic>>> downloadAllTransactions() async {
    if (!await isOnline) return [];
    try {
      final snap = await _col('transactions').get();
      return snap.docs
          .map((d) => d.data())
          .where((d) => d['deleted'] != true)
          .toList();
    } catch (e) {
      debugPrint('[Sync] Download transactions error: $e');
      return [];
    }
  }

  // ── WALLETS ───────────────────────────────────────────────────────────────

  static Future<void> uploadWallet(Map<String, dynamic> data) async {
    if (!await isOnline) return;
    try {
      await _col('wallets')
          .doc(data['id'] as String)
          .set(_sanitize(data), SetOptions(merge: true));
    } catch (e) {
      debugPrint('[Sync] Upload wallet error: $e');
    }
  }

  static Future<void> deleteWallet(String id) async {
    if (!await isOnline) return;
    try {
      await _col('wallets').doc(id).update({
        'deleted':   true,
        'deletedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('[Sync] Delete wallet error: $e');
    }
  }

  static Future<List<Map<String, dynamic>>> downloadAllWallets() async {
    if (!await isOnline) return [];
    try {
      final snap = await _col('wallets').get();
      return snap.docs
          .map((d) => d.data())
          .where((d) => d['deleted'] != true)
          .toList();
    } catch (e) {
      debugPrint('[Sync] Download wallets error: $e');
      return [];
    }
  }

  // ── BUDGETS ───────────────────────────────────────────────────────────────

  static Future<void> uploadBudget(Map<String, dynamic> data) async {
    if (!await isOnline) return;
    try {
      await _col('budgets')
          .doc(data['category'] as String)
          .set(_sanitize(data), SetOptions(merge: true));
    } catch (e) {
      debugPrint('[Sync] Upload budget error: $e');
    }
  }

  static Future<List<Map<String, dynamic>>> downloadAllBudgets() async {
    if (!await isOnline) return [];
    try {
      final snap = await _col('budgets').get();
      return snap.docs.map((d) => d.data()).toList();
    } catch (e) {
      debugPrint('[Sync] Download budgets error: $e');
      return [];
    }
  }

  // ── GOALS ─────────────────────────────────────────────────────────────────

  static Future<void> uploadGoal(Map<String, dynamic> data) async {
    if (!await isOnline) return;
    try {
      await _col('goals')
          .doc(data['id'] as String)
          .set(_sanitize(data), SetOptions(merge: true));
    } catch (e) {
      debugPrint('[Sync] Upload goal error: $e');
    }
  }

  // ── PENDING SYNC ──────────────────────────────────────────────────────────

  static Future<void> syncPendingTransactions(
      List<Map<String, dynamic>> pending,) async {
    if (!await isOnline) return;
    if (pending.isEmpty) return;
    debugPrint('[Sync] Syncing ${pending.length} pending transactions...');
    final batch = _firestore.batch();
    for (final data in pending) {
      final ref = _col('transactions').doc(data['id'] as String);
      batch.set(ref, _sanitize(data), SetOptions(merge: true));
    }
    try {
      await batch.commit();
      debugPrint('[Sync] Batch sync complete: ${pending.length} items');
    } catch (e) {
      debugPrint('[Sync] Batch sync error: $e');
    }
  }

  // ── FULL RESTORE ──────────────────────────────────────────────────────────

  static Future<SyncDownloadResult> downloadAll() async {
    if (!await isOnline) return SyncDownloadResult.empty();
    try {
      final results = await Future.wait([
        downloadAllTransactions(),
        downloadAllWallets(),
        downloadAllBudgets(),
      ]);
      return SyncDownloadResult(
        transactions: results[0],
        wallets:      results[1],
        budgets:      results[2],
      );
    } catch (e) {
      debugPrint('[Sync] Download all error: $e');
      return SyncDownloadResult.empty();
    }
  }

  // ── HELPER ────────────────────────────────────────────────────────────────

  static Map<String, dynamic> _sanitize(Map<String, dynamic> data) {
    final result = <String, dynamic>{};
    for (final entry in data.entries) {
      final value = entry.value;
      if (value == null) continue;
      if (value is DateTime) {
        result[entry.key] = Timestamp.fromDate(value);
      } else {
        result[entry.key] = value;
      }
    }
    result['updatedAt'] = FieldValue.serverTimestamp();
    result['platform']  = defaultTargetPlatform.name;
    return result;
  }
}

class SyncDownloadResult {
  final List<Map<String, dynamic>> transactions;
  final List<Map<String, dynamic>> wallets;
  final List<Map<String, dynamic>> budgets;

  const SyncDownloadResult({
    required this.transactions,
    required this.wallets,
    required this.budgets,
  });

  factory SyncDownloadResult.empty() => const SyncDownloadResult(
        transactions: [],
        wallets:      [],
        budgets:      [],
      );

  bool get isEmpty =>
      transactions.isEmpty && wallets.isEmpty && budgets.isEmpty;

  int get totalItems =>
      transactions.length + wallets.length + budgets.length;
}