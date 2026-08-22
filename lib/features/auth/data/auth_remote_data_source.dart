import 'package:chambapp_mobile/core/constants/app_constants.dart';
import 'package:chambapp_mobile/features/auth/data/user_model.dart';
import 'package:chambapp_mobile/features/auth/domain/user.dart';
import 'package:dio/dio.dart';

abstract interface class AuthRemoteDataSource {
  Future<AuthSession> login({required String email, required String password});
  Future<AuthSession> register(RegistrationInput input);
  Future<User> me({String? fallbackEmail});
  Future<void> logout();
  Future<void> logoutAll();
}

final class DioAuthRemoteDataSource implements AuthRemoteDataSource {
  DioAuthRemoteDataSource(this._dio);
  final Dio _dio;

  @override
  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/auth/login',
      data: {
        'email': email.trim(),
        'password': password,
        'device_name': AppConstants.deviceName,
      },
    );
    return _session(response.data!, fallbackEmail: email.trim());
  }

  @override
  Future<AuthSession> register(RegistrationInput input) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/auth/register',
      data: {
        'name': input.name.trim(),
        'email': input.email.trim(),
        'phone': input.phone.trim(),
        'role': input.role.apiValue,
        'password': input.password,
        'password_confirmation': input.passwordConfirmation,
        'device_name': AppConstants.deviceName,
      },
    );
    return _session(response.data!, fallbackEmail: input.email.trim());
  }

  @override
  Future<User> me({String? fallbackEmail}) async {
    final response = await _dio.get<Map<String, dynamic>>('/me');
    final data = _map(response.data?['data']);
    return UserModel.fromJson(data, fallbackEmail: fallbackEmail);
  }

  @override
  Future<void> logout() async => _dio.post<void>('/auth/logout');

  @override
  Future<void> logoutAll() async => _dio.post<void>('/auth/logout-all');

  AuthSession _session(
    Map<String, dynamic> body, {
    required String fallbackEmail,
  }) {
    final data = _map(body['data']);
    return AuthSession(
      token: data['token']?.toString() ?? '',
      user: UserModel.fromJson(
        _map(data['user']),
        fallbackEmail: fallbackEmail,
      ),
    );
  }

  Map<String, dynamic> _map(Object? value) =>
      value is Map ? Map<String, dynamic>.from(value) : <String, dynamic>{};
}
