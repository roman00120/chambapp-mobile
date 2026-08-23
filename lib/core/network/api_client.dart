import 'dart:async';

import 'package:chambapp_mobile/core/config/api_config.dart';
import 'package:chambapp_mobile/core/storage/session_storage.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

final class UnauthorizedEvents {
  final _controller = StreamController<void>.broadcast();
  Stream<void> get stream => _controller.stream;
  void notify() => _controller.add(null);
  void dispose() => _controller.close();
}

Dio buildDio({
  required SessionStorage storage,
  required UnauthorizedEvents unauthorizedEvents,
}) {
  final dio = Dio(
    BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: ApiConfig.timeout,
      receiveTimeout: ApiConfig.timeout,
      sendTimeout: ApiConfig.timeout,
      headers: const {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    ),
  );
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await storage.readToken();
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        if (ApiConfig.enableNetworkLogs) {
          debugPrint('API → ${options.method} ${options.uri.path}');
        }
        handler.next(options);
      },
      onResponse: (response, handler) {
        if (ApiConfig.enableNetworkLogs) {
          debugPrint(
            'API ← ${response.statusCode} ${response.requestOptions.uri.path}',
          );
        }
        handler.next(response);
      },
      onError: (error, handler) {
        final path = error.requestOptions.path;
        final isAuthAttempt =
            path.contains('/auth/login') ||
            path.contains('/auth/register') ||
            path.contains('/auth/google');
        if (error.response?.statusCode == 401 && !isAuthAttempt) {
          unauthorizedEvents.notify();
        }
        if (ApiConfig.enableNetworkLogs) {
          debugPrint(
            'API ✕ ${error.response?.statusCode ?? 'NETWORK'} ${error.requestOptions.uri.path}',
          );
        }
        handler.next(error);
      },
    ),
  );
  return dio;
}
