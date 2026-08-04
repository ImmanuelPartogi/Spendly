import 'package:equatable/equatable.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthUIState extends Equatable {
  final AuthStatus status;
  final String? errorMessage;

  const AuthUIState({
    this.status = AuthStatus.initial,
    this.errorMessage,
  });

  bool get isLoading => status == AuthStatus.loading;

  AuthUIState copyWith({
    AuthStatus? status,
    String? errorMessage,
  }) {
    return AuthUIState(
      status: status ?? this.status,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, errorMessage];
}
