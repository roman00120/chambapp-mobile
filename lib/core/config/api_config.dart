import 'package:flutter/foundation.dart';

enum AppEnvironment { development, production }

final class ApiConfig {
  ApiConfig._();

  static const apiVersion = 'v1';
  static const timeout = Duration(seconds: 20);
  static const environmentName = String.fromEnvironment(
    'APP_ENV',
    defaultValue: 'development',
  );
  static const _definedBaseUrl = String.fromEnvironment('API_BASE_URL');

  static AppEnvironment get environment => environmentName == 'production'
      ? AppEnvironment.production
      : AppEnvironment.development;

  static String get baseUrl {
    if (kReleaseMode && environment != AppEnvironment.production) {
      throw StateError(
        'Las compilaciones release requieren APP_ENV=production.',
      );
    }
    if (environment == AppEnvironment.production && _definedBaseUrl.isEmpty) {
      throw StateError(
        'API_BASE_URL es obligatorio para el entorno production.',
      );
    }
    final value = _definedBaseUrl.isEmpty
        ? 'http://10.0.2.2:8000/api/v1'
        : _definedBaseUrl;
    final uri = Uri.tryParse(value);
    if (uri == null || !uri.hasScheme || !uri.hasAuthority) {
      throw StateError('API_BASE_URL no es una URL válida.');
    }
    if (environment == AppEnvironment.production && uri.scheme != 'https') {
      throw StateError('El entorno production requiere una API HTTPS.');
    }
    return value.replaceFirst(RegExp(r'/$'), '');
  }

  static bool get enableNetworkLogs =>
      kDebugMode && environment == AppEnvironment.development;
}
