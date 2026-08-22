import 'package:chambapp_mobile/features/auth/domain/user.dart';

enum AuthStatus { checking, authenticated, unauthenticated }

final class AuthState {
  const AuthState({
    this.status = AuthStatus.checking,
    this.user,
    this.isSubmitting = false,
    this.message,
    this.fieldErrors = const {},
  });

  final AuthStatus status;
  final User? user;
  final bool isSubmitting;
  final String? message;
  final Map<String, String> fieldErrors;

  AuthState copyWith({
    AuthStatus? status,
    User? user,
    bool? isSubmitting,
    String? message,
    bool clearMessage = false,
    Map<String, String>? fieldErrors,
  }) => AuthState(
    status: status ?? this.status,
    user: user ?? this.user,
    isSubmitting: isSubmitting ?? this.isSubmitting,
    message: clearMessage ? null : message ?? this.message,
    fieldErrors: fieldErrors ?? this.fieldErrors,
  );
}
