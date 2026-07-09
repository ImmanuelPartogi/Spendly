import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ─── Stream auth state Firebase ───────────────────────────────────────────────
// Setiap kali login/logout, semua widget yang watch ini langsung rebuild.

final firebaseAuthProvider = Provider<FirebaseAuth>(
  (_) => FirebaseAuth.instance,
);

/// `Stream<User?>` — null = belum login, User = sudah login
final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(firebaseAuthProvider).authStateChanges();
});

/// Shortcut: apakah sudah login
final isLoggedInProvider = Provider<bool>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.valueOrNull != null;
});

/// UID user yang sedang aktif
final currentUserIdProvider = Provider<String?>((ref) {
  return ref.watch(authStateProvider).valueOrNull?.uid;
});

/// Apakah user anonymous (belum upgrade ke email)
final isAnonymousProvider = Provider<bool>((ref) {
  final user = ref.watch(authStateProvider).valueOrNull;
  return user?.isAnonymous ?? true;
});

/// Email user (null jika anonymous)
final currentUserEmailProvider = Provider<String?>((ref) {
  return ref.watch(authStateProvider).valueOrNull?.email;
});