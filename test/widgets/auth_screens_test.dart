import 'dart:async';

import 'package:chambapp_mobile/app/providers.dart';
import 'package:chambapp_mobile/core/errors/app_exception.dart';
import 'package:chambapp_mobile/core/theme/app_theme.dart';
import 'package:chambapp_mobile/features/auth/presentation/login_screen.dart';
import 'package:chambapp_mobile/features/auth/presentation/register_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fakes.dart';

Widget _app(Widget child, FakeAuthRepository repository) => ProviderScope(
  overrides: [authRepositoryProvider.overrideWithValue(repository)],
  child: MaterialApp(theme: AppTheme.light, home: child),
);

void main() {
  testWidgets('login renderiza sus campos y valida vacíos', (tester) async {
    await tester.pumpWidget(_app(const LoginScreen(), FakeAuthRepository()));
    expect(find.text('Iniciar sesión'), findsWidgets);
    expect(find.byKey(const Key('login_email')), findsOneWidget);
    expect(find.byKey(const Key('login_password')), findsOneWidget);

    await tester.tap(find.byKey(const Key('login_submit')));
    await tester.pump();
    expect(find.text('Escribe tu correo electrónico.'), findsOneWidget);
    expect(find.text('Escribe tu contraseña.'), findsOneWidget);
  });

  testWidgets('registro renderiza cuenta cliente y profesional', (
    tester,
  ) async {
    await tester.pumpWidget(_app(const RegisterScreen(), FakeAuthRepository()));
    expect(find.text('Crear cuenta'), findsWidgets);
    expect(find.text('Quiero contratar servicios'), findsOneWidget);
    expect(find.text('Quiero ofrecer mis servicios'), findsOneWidget);
  });

  testWidgets('login muestra loading mientras espera la API', (tester) async {
    final repository = FakeAuthRepository()..loginCompleter = Completer();
    await tester.pumpWidget(_app(const LoginScreen(), repository));
    await tester.enterText(
      find.byKey(const Key('login_email')),
      'ana@example.test',
    );
    await tester.enterText(find.byKey(const Key('login_password')), 'secret');
    await tester.tap(find.byKey(const Key('login_submit')));
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    repository.loginCompleter!.complete(testSession);
    await tester.pump();
  });

  testWidgets('login presenta un error de dominio legible', (tester) async {
    final repository = FakeAuthRepository()
      ..loginError = const AppException(
        message: 'Correo o contraseña incorrectos.',
        statusCode: 401,
      );
    await tester.pumpWidget(_app(const LoginScreen(), repository));
    await tester.enterText(
      find.byKey(const Key('login_email')),
      'ana@example.test',
    );
    await tester.enterText(
      find.byKey(const Key('login_password')),
      'incorrecta',
    );
    await tester.tap(find.byKey(const Key('login_submit')));
    await tester.pump();
    expect(find.byKey(const Key('login_error')), findsOneWidget);
    expect(find.text('Correo o contraseña incorrectos.'), findsWidgets);
  });

  for (final size in const [Size(320, 568), Size(390, 844), Size(430, 932)]) {
    testWidgets(
      'login se adapta a ${size.width.toInt()}x${size.height.toInt()}',
      (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(
          _app(const LoginScreen(), FakeAuthRepository()),
        );
        expect(tester.takeException(), isNull);
        expect(find.byKey(const Key('login_submit')), findsOneWidget);
      },
    );
  }
}
