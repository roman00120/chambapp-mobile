import 'dart:io';

import 'package:chambapp_mobile/core/errors/app_exception.dart';
import 'package:dio/dio.dart';

final class ApiErrorMapper {
  const ApiErrorMapper();

  AppException map(Object error) {
    if (error is AppException) return error;
    if (error is! DioException) {
      return const AppException(
        message: 'Ocurrió un problema. Intenta nuevamente.',
      );
    }

    final status = error.response?.statusCode;
    final body = error.response?.data;
    final map = body is Map
        ? Map<String, dynamic>.from(body)
        : <String, dynamic>{};
    final code = map['code']?.toString();
    final fieldErrors = _fieldErrors(map['errors']);

    if (_isNetworkError(error)) {
      return const AppException(message: 'Revisa tu conexión a Internet.');
    }
    if (code == 'INVALID_CREDENTIALS') {
      return AppException(
        message: 'Correo o contraseña incorrectos.',
        statusCode: status,
        code: code,
      );
    }

    final backendMessage = _sanitizeErrorMessage(map['message']?.toString());
    final message = switch (status) {
      401 => 'Tu sesión expiró. Inicia sesión nuevamente.',
      403 =>
        backendMessage?.isNotEmpty == true
            ? backendMessage!
            : 'No tienes permiso para realizar esta acción.',
      404 => 'No encontramos lo que buscas.',
      409 =>
        backendMessage?.isNotEmpty == true
            ? backendMessage!
            : 'La operación entra en conflicto con el estado actual.',
      422 =>
        fieldErrors.values.firstOrNull ??
            (backendMessage?.isNotEmpty == true
                ? backendMessage!
                : 'Revisa los datos ingresados.'),
      429 => 'Estamos actualizando demasiado rápido. Intenta de nuevo en unos segundos.',
      int value when value >= 500 => 'Ocurrió un problema. Intenta nuevamente.',
      _ =>
        backendMessage?.isNotEmpty == true
            ? backendMessage!
            : 'No pudimos completar la solicitud.',
    };
    return AppException(
      message: message,
      statusCode: status,
      code: code,
      fieldErrors: fieldErrors,
    );
  }

  bool _isNetworkError(DioException error) =>
      error.type == DioExceptionType.connectionError ||
      error.type == DioExceptionType.connectionTimeout ||
      error.type == DioExceptionType.receiveTimeout ||
      error.type == DioExceptionType.sendTimeout ||
      error.error is SocketException;

  Map<String, String> _fieldErrors(Object? raw) {
    if (raw is! Map) return const {};
    return raw.map((key, value) {
      final message = value is List && value.isNotEmpty ? value.first : value;
      return MapEntry(
        key.toString(),
        _sanitizeErrorMessage(message?.toString()) ?? 'Dato inválido.',
      );
    });
  }

  String? _sanitizeErrorMessage(String? rawMessage) {
    if (rawMessage == null) return null;
    final trimmed = rawMessage.trim();
    if (trimmed.isEmpty) return null;
    if (trimmed.startsWith('validation.')) {
      if (trimmed == 'validation.required') return 'Este campo es obligatorio.';
      if (trimmed.startsWith('validation.min')) {
        return 'El valor ingresado es menor al permitido.';
      }
      if (trimmed.startsWith('validation.max')) {
        return 'El valor ingresado excede el límite permitido.';
      }
      if (trimmed.startsWith('validation.numeric') ||
          trimmed.startsWith('validation.integer')) {
        return 'Ingresa un valor numérico válido.';
      }
      return 'Dato inválido.';
    }
    return trimmed;
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
