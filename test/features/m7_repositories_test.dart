import 'package:chambapp_mobile/core/errors/api_error_mapper.dart';
import 'package:chambapp_mobile/features/catalog/data/catalog_repositories_impl.dart';
import 'package:chambapp_mobile/features/notifications/data/notification_repository_impl.dart';
import 'package:chambapp_mobile/features/reviews/data/review_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/dio_test_adapter.dart';

void main() {
  test(
    'ReviewRepository publica solo rating y comentario normalizado',
    () async {
      final adapter = DioTestAdapter(
        (_) => jsonResponse({
          'data': {
            'id': 8,
            'rating': 5,
            'comment': 'Excelente trabajo',
            'client_name': 'Ana',
          },
        }, status: 201),
      );
      final repository = ApiReviewRepository(
        testDio(adapter),
        const ApiErrorMapper(),
      );

      final review = await repository.create(
        12,
        rating: 5,
        comment: '  Excelente trabajo  ',
      );

      expect(review.rating, 5);
      expect(adapter.requests.single.path, '/jobs/12/review');
      expect(adapter.requests.single.data, {
        'rating': 5,
        'comment': 'Excelente trabajo',
      });
    },
  );

  test('notificaciones conservan contador global y destinos seguros', () async {
    final adapter = DioTestAdapter(
      (options) => options.path == '/notifications'
          ? jsonResponse({
              'data': [
                {
                  'id': 'safe',
                  'type': 'job.updated',
                  'title': 'Cambio de estado',
                  'message': 'Tu chamba cambió.',
                  'destination': {'kind': 'job', 'id': 12},
                  'read_at': null,
                },
                {
                  'id': 'unsafe',
                  'type': 'unknown.future.event',
                  'title': 'Aviso',
                  'message': 'Mensaje compatible',
                  'destination': {'kind': 'external_url', 'id': 99},
                  'read_at': '2026-08-21T10:00:00Z',
                },
              ],
              'meta': {'unread_count': 27},
            })
          : jsonResponse({
              'data': {
                'id': 'safe',
                'type': 'job.updated',
                'title': 'Cambio de estado',
                'message': 'Tu chamba cambió.',
                'destination': {'kind': 'job', 'id': 12},
                'read_at': '2026-08-21T10:00:00Z',
              },
            }),
    );
    final repository = ApiNotificationRepository(
      testDio(adapter),
      const ApiErrorMapper(),
    );

    final page = await repository.getNotifications(page: 2);
    expect(page.unreadCount, 27);
    expect(page.items.first.destination?.id, 12);
    expect(page.items.last.destination, isNull);
    expect(adapter.requests.first.queryParameters['page'], 2);
    expect((await repository.markRead('safe')).unread, isFalse);
    await repository.markAllRead();
    expect(adapter.requests.map((item) => item.path), [
      '/notifications',
      '/notifications/safe/read',
      '/notifications/read-all',
    ]);
  });

  test('reseñas públicas se leen desde el endpoint del profesional', () async {
    final adapter = DioTestAdapter(
      (_) => jsonResponse({
        'data': [
          {
            'id': 4,
            'rating': 4,
            'comment': 'Buen servicio',
            'client_name': 'Cliente',
          },
        ],
      }),
    );
    final repository = ApiProfessionalRepository(
      testDio(adapter),
      const ApiErrorMapper(),
    );

    final reviews = await repository.getReviews(3, page: 2);

    expect(reviews.single.comment, 'Buen servicio');
    expect(adapter.requests.single.path, '/professionals/3/reviews');
    expect(adapter.requests.single.queryParameters['page'], 2);
  });
}
