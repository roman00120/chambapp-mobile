import 'dart:async';

import 'package:chambapp_mobile/core/errors/app_exception.dart';
import 'package:chambapp_mobile/core/theme/app_theme.dart';
import 'package:chambapp_mobile/features/catalog/domain/catalog_models.dart';
import 'package:chambapp_mobile/features/reviews/domain/review_repository.dart';
import 'package:chambapp_mobile/features/reviews/presentation/review_form_screen.dart';
import 'package:chambapp_mobile/features/reviews/presentation/review_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _review = ReviewModel(
  id: 8,
  rating: 5,
  clientName: 'Ana',
  comment: 'Excelente trabajo',
);

final class _Reviews implements ReviewRepository {
  int calls = 0;
  int? rating;
  String? comment;
  Object? error;
  Completer<ReviewModel>? completer;

  @override
  Future<ReviewModel> create(
    int jobId, {
    required int rating,
    String? comment,
  }) {
    calls++;
    this.rating = rating;
    this.comment = comment;
    if (error != null) return Future.error(error!);
    return completer?.future ?? Future.value(_review);
  }
}

Widget _screen(_Reviews reviews) => ProviderScope(
  overrides: [reviewRepositoryProvider.overrideWithValue(reviews)],
  child: MaterialApp(
    theme: AppTheme.light,
    home: const ReviewFormScreen(jobId: 12, professionalId: 3),
  ),
);

void main() {
  testWidgets('exige 1 a 5 estrellas y bloquea doble publicación', (
    tester,
  ) async {
    final reviews = _Reviews()..completer = Completer<ReviewModel>();
    await tester.pumpWidget(_screen(reviews));

    await tester.tap(find.text('Publicar reseña'));
    await tester.pump();
    expect(find.text('Selecciona una calificación de 1 a 5.'), findsOneWidget);

    await tester.tap(find.byKey(const Key('rating_5')));
    await tester.pump();
    expect(find.text('Excelente'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'Excelente trabajo');
    await tester.tap(find.text('Publicar reseña'));
    await tester.tap(find.text('Publicar reseña'));
    await tester.pump();

    expect(reviews.calls, 1);
    expect(reviews.rating, 5);
    expect(reviews.comment, 'Excelente trabajo');
    reviews.completer!.complete(_review);
    await tester.pumpAndSettle();
  });

  testWidgets('muestra el bloqueo de datos de contacto en comentario', (
    tester,
  ) async {
    final reviews = _Reviews()
      ..error = const AppException(
        message: 'Los datos de contacto no están permitidos.',
        statusCode: 422,
        fieldErrors: {'comment': 'No compartas teléfono, email ni WhatsApp.'},
      );
    await tester.pumpWidget(_screen(reviews));
    await tester.tap(find.byKey(const Key('rating_4')));
    await tester.tap(find.text('Publicar reseña'));
    await tester.pumpAndSettle();

    expect(
      find.text('No compartas teléfono, email ni WhatsApp.'),
      findsOneWidget,
    );
  });
}
