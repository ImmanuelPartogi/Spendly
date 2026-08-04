import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/domain/services/auth_service.dart';

final pinEnabledProvider = FutureProvider<bool>((ref) async {
  return AuthService.isPinEnabled();
});

final bottomNavIndexProvider = StateProvider<int>((ref) => 0);
final selectedPeriodProvider = StateProvider<String>((ref) => 'Monthly');
final restoreReadyProvider = StateProvider<bool>((ref) => false);
