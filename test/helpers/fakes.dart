import 'dart:async';

import 'package:chambapp_mobile/core/storage/session_storage.dart';
import 'package:chambapp_mobile/features/auth/data/auth_remote_data_source.dart';
import 'package:chambapp_mobile/features/auth/domain/auth_repository.dart';
import 'package:chambapp_mobile/features/auth/domain/user.dart';

const testUser = User(
  id: 7,
  name: 'Ana Pérez',
  role: UserRole.client,
  email: 'ana@example.test',
  status: 'active',
);

const testSession = AuthSession(token: 'test-token', user: testUser);

final class MemorySessionStorage implements SessionStorage {
  String? token;
  String? email;
  int clearCount = 0;

  @override
  Future<void> clear() async {
    token = null;
    email = null;
    clearCount++;
  }

  @override
  Future<String?> readEmail() async => email;

  @override
  Future<String?> readToken() async => token;

  @override
  Future<void> save({required String token, required String email}) async {
    this.token = token;
    this.email = email;
  }
}

final class FakeRemoteDataSource implements AuthRemoteDataSource {
  AuthSession session = testSession;
  User meResult = testUser;
  Object? error;
  bool logoutCalled = false;
  RegistrationRequirements requirements = testRegistrationRequirements;
  RegistrationRequirements? professionalRequirements;

  @override
  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    if (error != null) throw error!;
    return session;
  }

  @override
  Future<AuthSession> loginWithGoogle({required String idToken}) async {
    if (error != null) throw error!;
    return session;
  }

  @override
  Future<AuthSession> register(RegistrationInput input) async {
    if (error != null) throw error!;
    return session;
  }

  @override
  Future<RegistrationRequirements> registrationRequirements(
    UserRole role,
  ) async => role == UserRole.professional && professionalRequirements != null
      ? professionalRequirements!
      : requirements;

  @override
  Future<User> me({String? fallbackEmail}) async {
    if (error != null) throw error!;
    return meResult.copyWith(email: fallbackEmail);
  }

  @override
  Future<void> logout() async {
    logoutCalled = true;
    if (error != null) throw error!;
  }

  @override
  Future<void> logoutAll() async {
    if (error != null) throw error!;
  }
}

final class FakeAuthRepository implements AuthRepository {
  Object? loginError;
  Completer<AuthSession>? loginCompleter;
  RegistrationRequirements requirements = testRegistrationRequirements;
  RegistrationRequirements? professionalRequirements;
  RegistrationInput? lastRegistration;

  @override
  Future<AuthSession> login({required String email, required String password}) {
    if (loginError != null) return Future.error(loginError!);
    return loginCompleter?.future ?? Future.value(testSession);
  }

  @override
  Future<AuthSession> loginWithGoogle({required String idToken}) async =>
      testSession;

  @override
  Future<AuthSession> register(RegistrationInput input) async {
    lastRegistration = input;
    return testSession;
  }

  @override
  Future<RegistrationRequirements> registrationRequirements(
    UserRole role,
  ) async => role == UserRole.professional && professionalRequirements != null
      ? professionalRequirements!
      : requirements;

  @override
  Future<User?> restoreSession() async => null;

  @override
  Future<User> me() async => testUser;

  @override
  Future<void> logout() async {}

  @override
  Future<void> logoutAll() async {}

  @override
  Future<void> clearLocalSession() async {}
}

final testRegistrationRequirements = RegistrationRequirements(
  acceptanceRequired: true,
  registrationAvailable: true,
  documents: [
    LegalDocument(
      document: 'terms',
      title: 'Términos y Condiciones',
      version: '2026-08-26',
      url: Uri.parse('https://chambapp.com.mx/terminos'),
    ),
    LegalDocument(
      document: 'privacy',
      title: 'Aviso de Privacidad',
      version: '2026-08-26',
      url: Uri.parse('https://chambapp.com.mx/privacidad'),
    ),
  ],
);
