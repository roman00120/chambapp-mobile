import 'package:chambapp_mobile/core/errors/api_error_mapper.dart';
import 'package:chambapp_mobile/core/errors/app_exception.dart';
import 'package:chambapp_mobile/core/storage/session_storage.dart';
import 'package:chambapp_mobile/features/auth/data/auth_remote_data_source.dart';
import 'package:chambapp_mobile/features/auth/domain/auth_repository.dart';
import 'package:chambapp_mobile/features/auth/domain/user.dart';

final class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._remote, this._storage, this._errors);

  final AuthRemoteDataSource _remote;
  final SessionStorage _storage;
  final ApiErrorMapper _errors;

  @override
  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    try {
      final session = await _remote.login(email: email, password: password);
      _ensureSupportedRole(session.user);
      await _storage.save(token: session.token, email: email.trim());
      return session;
    } catch (error) {
      throw _errors.map(error);
    }
  }

  @override
  Future<AuthSession> loginWithGoogle({required String idToken}) async {
    try {
      final session = await _remote.loginWithGoogle(idToken: idToken);
      _ensureSupportedRole(session.user);
      await _storage.save(
        token: session.token,
        email: session.user.email ?? '',
      );
      return session;
    } catch (error) {
      throw _errors.map(error);
    }
  }

  @override
  Future<AuthSession> register(RegistrationInput input) async {
    try {
      final session = await _remote.register(input);
      _ensureSupportedRole(session.user);
      await _storage.save(token: session.token, email: input.email.trim());
      return session;
    } catch (error) {
      throw _errors.map(error);
    }
  }

  @override
  Future<User?> restoreSession() async {
    final token = await _storage.readToken();
    if (token == null || token.isEmpty) return null;
    try {
      final user = await _remote.me(fallbackEmail: await _storage.readEmail());
      _ensureSupportedRole(user);
      return user;
    } catch (error) {
      final mapped = _errors.map(error);
      if (mapped.isUnauthorized || mapped.statusCode == 403) {
        await _storage.clear();
      }
      throw mapped;
    }
  }

  @override
  Future<User> me() async {
    try {
      return await _remote.me(fallbackEmail: await _storage.readEmail());
    } catch (error) {
      throw _errors.map(error);
    }
  }

  @override
  Future<void> logout() async {
    try {
      await _remote.logout();
    } catch (_) {
      // La sesión local siempre se elimina, incluso si el token ya expiró.
    } finally {
      await _storage.clear();
    }
  }

  @override
  Future<void> logoutAll() async {
    try {
      await _remote.logoutAll();
    } catch (error) {
      throw _errors.map(error);
    } finally {
      await _storage.clear();
    }
  }

  @override
  Future<void> clearLocalSession() => _storage.clear();

  void _ensureSupportedRole(User user) {
    if (user.role == UserRole.unsupported) {
      throw const AppException(
        message: 'Esta cuenta no está disponible en la aplicación móvil.',
        statusCode: 403,
        code: 'ROLE_NOT_SUPPORTED',
      );
    }
  }
}
