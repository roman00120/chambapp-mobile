import 'package:chambapp_mobile/core/errors/api_error_mapper.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const mapper = ApiErrorMapper();

  test('mapea falta de conexión a un mensaje amigable', () {
    final error = DioException(
      requestOptions: RequestOptions(path: '/me'),
      type: DioExceptionType.connectionError,
    );
    expect(mapper.map(error).message, 'Revisa tu conexión a Internet.');
  });

  test('mapea 422 y conserva errores por campo', () {
    final error = DioException.badResponse(
      statusCode: 422,
      requestOptions: RequestOptions(path: '/auth/register'),
      response: Response(
        requestOptions: RequestOptions(path: '/auth/register'),
        statusCode: 422,
        data: {
          'message': 'Datos inválidos',
          'errors': {
            'email': ['El correo ya está registrado.'],
          },
        },
      ),
    );
    final mapped = mapper.map(error);
    expect(mapped.statusCode, 422);
    expect(mapped.fieldErrors['email'], 'El correo ya está registrado.');
    expect(mapped.message, 'El correo ya está registrado.');
  });

  test('mapea credenciales inválidas sin mostrar HTTP', () {
    final error = DioException.badResponse(
      statusCode: 401,
      requestOptions: RequestOptions(path: '/auth/login'),
      response: Response(
        requestOptions: RequestOptions(path: '/auth/login'),
        statusCode: 401,
        data: {'code': 'INVALID_CREDENTIALS'},
      ),
    );
    expect(mapper.map(error).message, 'Correo o contraseña incorrectos.');
  });

  test('sanitiza claves internas como validation.required a mensajes en español', () {
    final error = DioException.badResponse(
      statusCode: 422,
      requestOptions: RequestOptions(path: '/professional/profile'),
      response: Response(
        requestOptions: RequestOptions(path: '/professional/profile'),
        statusCode: 422,
        data: {
          'message': 'validation.required',
          'errors': {
            'experience_years': ['validation.required'],
            'name': ['validation.min.string'],
          },
        },
      ),
    );
    final mapped = mapper.map(error);
    expect(mapped.statusCode, 422);
    expect(
      mapped.fieldErrors['experience_years'],
      'Este campo es obligatorio.',
    );
    expect(
      mapped.fieldErrors['name'],
      'El valor ingresado es menor al permitido.',
    );
    expect(mapped.message, 'Este campo es obligatorio.');
    expect(mapped.message, isNot(contains('validation.')));
  });
}
