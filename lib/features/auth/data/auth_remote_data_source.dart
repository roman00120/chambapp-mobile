import 'package:chambapp_mobile/core/constants/app_constants.dart';
import 'package:chambapp_mobile/features/auth/data/user_model.dart';
import 'package:chambapp_mobile/features/auth/domain/user.dart';
import 'package:dio/dio.dart';

abstract interface class AuthRemoteDataSource {
  Future<AuthSession> login({required String email, required String password});
  Future<AuthSession> loginWithGoogle({required String idToken});
  Future<AuthSession> register(RegistrationInput input);
  Future<RegistrationRequirements> registrationRequirements(UserRole role);
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
  Future<AuthSession> loginWithGoogle({required String idToken}) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/auth/google',
      data: {'id_token': idToken, 'device_name': AppConstants.deviceName},
    );
    return _session(response.data!, fallbackEmail: '');
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
        'legal_accepted': input.legalAccepted,
        'legal_documents': input.legalDocuments,
      },
      options: Options(headers: {'X-Chambapp-Platform': 'flutter'}),
    );
    return _session(response.data!, fallbackEmail: input.email.trim());
  }

  @override
  Future<RegistrationRequirements> registrationRequirements(
    UserRole role,
  ) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/auth/registration-requirements',
      queryParameters: {'role': role.apiValue},
    );
    final data = _map(response.data?['data']);
    final rawDocuments = data['documents'];
    final documents = rawDocuments is List
        ? rawDocuments
              .whereType<Map>()
              .map((item) {
                final value = Map<String, dynamic>.from(item);
                return LegalDocument(
                  document: value['document']?.toString() ?? '',
                  title: value['title']?.toString() ?? '',
                  version: value['version']?.toString() ?? '',
                  url: Uri.parse(value['url']?.toString() ?? ''),
                );
              })
              .where(
                (item) =>
                    item.document.isNotEmpty &&
                    item.version.isNotEmpty &&
                    item.url.hasScheme,
              )
              .toList()
        : <LegalDocument>[];
    return RegistrationRequirements(
      acceptanceRequired: data['acceptance_required'] == true,
      registrationAvailable: data['registration_available'] == true,
      documents: documents,
    );
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
