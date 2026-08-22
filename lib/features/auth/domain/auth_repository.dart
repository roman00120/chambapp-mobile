import 'package:chambapp_mobile/features/auth/domain/user.dart';

abstract interface class AuthRepository {
  Future<AuthSession> login({required String email, required String password});
  Future<AuthSession> register(RegistrationInput input);
  Future<User?> restoreSession();
  Future<User> me();
  Future<void> logout();
  Future<void> logoutAll();
  Future<void> clearLocalSession();
}
