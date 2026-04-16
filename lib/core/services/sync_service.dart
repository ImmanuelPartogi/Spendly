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

  /// Dokumen utama user — untuk settings seperti PIN
  static DocumentReference<Map<String, dynamic>> get _userDoc {
    final uid = FirebaseAuthService.currentUserId;
    if (uid == null) throw Exception('User not logged in');
    return _firestore.collection('users').doc(uid);
  }

  // ── PIN LOOKUP (pra-login, publicly readable) ─────────────────────────────
  //
  // Collection: pin_lookup/{email_lowercase}
  // Fields    : { pinEnabled: bool, pinHash: string, updatedAt: timestamp }
  //
  // Dokumen ini TIDAK menyimpan PIN mentah — hanya hash-nya.
  // Hash format: sha256(pin + ":" + email.toLowerCase())
  //
  // Firestore Rules yang dibutuhkan:
  //   match /pin_lookup/{emailKey} {
  //     allow read: if true;
  //     allow write: if request.auth != null;
  //   }
  //
  // Dipakai oleh LoginScreen untuk menentukan apakah harus tampilkan
  // PIN step atau password step, sebelum user terautentikasi ke Firebase.
  //

  static DocumentReference<Map<String, dynamic>> _pinLookupDoc(String email) =>
      _firestore
          .collection('pin_lookup')
          .doc(email.toLowerCase().trim());

  /// Upload/update pin_lookup entry untuk email.
  /// Dipanggil oleh AuthService.setPin(), disablePin(), dan restorePin().
  static Future<void> uploadPinLookup({
    required String email,
    required bool   enabled,
    required String pinHash,
  }) async {
    if (email.isEmpty) return;
    if (!await isOnline) return;
    try {
      await _pinLookupDoc(email).set(
        {
          'pinEnabled': enabled,
          'pinHash':    enabled ? pinHash : FieldValue.delete(),
          'updatedAt':  FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
      debugPrint('[Sync] pin_lookup updated (email=$email, enabled=$enabled)');
    } catch (e) {
      debugPrint('[Sync] Upload pin_lookup error: $e');
    }
  }

  /// Cek PIN status untuk email — tanpa perlu Firebase Auth.
  /// Return: { 'pinEnabled': bool, 'pinHash': String } atau null jika tidak ada.
  static Future<Map<String, dynamic>?> checkPinByEmail(String email) async {
    if (email.isEmpty) return null;
    if (!await isOnline) return null;
    try {
      final snap = await _pinLookupDoc(email).get();
      if (!snap.exists) return null;
      final data = snap.data();
      if (data == null) return null;
      final pinEnabled = data['pinEnabled'] as bool? ?? false;
      final pinHash    = data['pinHash'] as String?;
      if (!pinEnabled || pinHash == null || pinHash.isEmpty) return null;
      return {'pinEnabled': pinEnabled, 'pinHash': pinHash};
    } catch (e) {
      debugPrint('[Sync] Check pin_lookup error: $e');
      return null;
    }
  }

  // ── PIN (users/{uid}) ─────────────────────────────────────────────────────
  //
  // PIN mentah (terenkripsi implisit oleh Firestore rules) disimpan di
  // dokumen utama user: users/{uid}
  // Fields: { pin: string, pinEnabled: bool, updatedAt: timestamp }
  //
  // Ini adalah sumber kebenaran PIN yang sebenarnya, dilindungi auth rules.
  // pin_lookup hanya menyimpan hash-nya untuk keperluan lookup pra-login.
  //

  static Future<void> uploadPin({
    required String pin,
    required bool   enabled,
  }) async {
    if (!await isOnline) return;
    try {
      await _userDoc.set(
        {
          'pin':        pin,
          'pinEnabled': enabled,
          'updatedAt':  FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
      debugPrint('[Sync] PIN uploaded (enabled=$enabled)');
    } catch (e) {
      debugPrint('[Sync] Upload PIN error: $e');
    }
  }

  /// Mengembalikan {'pin': String, 'pinEnabled': bool} atau null jika tidak ada.
  static Future<Map<String, dynamic>?> downloadPin() async {
    if (!await isOnline) return null;
    try {
      final snap = await _userDoc.get();
      if (!snap.exists) return null;
      final data = snap.data();
      if (data == null) return null;
      final pin        = data['pin'] as String?;
      final pinEnabled = data['pinEnabled'] as bool? ?? false;
      if (pin == null) return null;
      return {'pin': pin, 'pinEnabled': pinEnabled};
    } catch (e) {
      debugPrint('[Sync] Download PIN error: $e');
      return null;
    }
  }

  static Future<void> disablePin() async {
    if (!await isOnline) return;
    try {
      await _userDoc.set(
        {
          'pin':        null,
          'pinEnabled': false,
          'updatedAt':  FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
      debugPrint('[Sync] PIN disabled in Firebase');
    } catch (e) {
      debugPrint('[Sync] Disable PIN error: $e');
    }
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
      List<Map<String, dynamic>> pending) async {
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
        downloadPin(),
      ]);
      return SyncDownloadResult(
        transactions: results[0] as List<Map<String, dynamic>>,
        wallets:      results[1] as List<Map<String, dynamic>>,
        budgets:      results[2] as List<Map<String, dynamic>>,
        pinData:      results[3] as Map<String, dynamic>?,
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

  /// Data PIN dari Firebase: {'pin': String, 'pinEnabled': bool}
  /// null = user belum pernah set PIN
  final Map<String, dynamic>? pinData;

  const SyncDownloadResult({
    required this.transactions,
    required this.wallets,
    required this.budgets,
    this.pinData,
  });

  factory SyncDownloadResult.empty() => const SyncDownloadResult(
        transactions: [],
        wallets:      [],
        budgets:      [],
        pinData:      null,
      );

  bool get isEmpty =>
      transactions.isEmpty && wallets.isEmpty && budgets.isEmpty;

  int get totalItems =>
      transactions.length + wallets.length + budgets.length;
}