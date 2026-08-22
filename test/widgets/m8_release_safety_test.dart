import 'package:chambapp_mobile/core/theme/app_theme.dart';
import 'package:chambapp_mobile/shared/widgets/error_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('errores técnicos no se muestran al usuario', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: ErrorState(
          title: 'No pudimos cargar',
          message:
              'DioException: connection failed https://internal.example.test',
          onRetry: () {},
        ),
      ),
    );

    expect(find.textContaining('DioException'), findsNothing);
    expect(find.textContaining('internal.example.test'), findsNothing);
    expect(
      find.text('No pudimos completar la solicitud. Intenta nuevamente.'),
      findsOneWidget,
    );
  });
}
