import 'package:chambapp_mobile/core/errors/api_error_mapper.dart';
import 'package:chambapp_mobile/features/catalog/data/catalog_repositories_impl.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/dio_test_adapter.dart';

void main() {
  test('CategoryRepository obtiene y parsea categorías', () async {
    final adapter = DioTestAdapter(
      (_) => jsonResponse({
        'data': [
          {'id': 1, 'name': 'Plomería', 'slug': 'plomeria', 'icon': null},
        ],
      }),
    );
    final repository = ApiCategoryRepository(
      testDio(adapter),
      const ApiErrorMapper(),
    );
    final categories = await repository.getCategories();
    expect(categories.single.name, 'Plomería');
    expect(adapter.requests.single.path, '/categories');
  });

  test('ServiceRepository envía búsqueda y categoría al backend', () async {
    final adapter = DioTestAdapter(
      (_) => jsonResponse({
        'data': [
          {
            'id': 9,
            'title': 'Reparación de fuga',
            'description': 'Servicio profesional',
            'price_type': 'quote',
            'currency': 'MXN',
            'category': {'id': 1, 'name': 'Plomería', 'slug': 'plomeria'},
            'professional': {
              'id': 3,
              'name': 'Luis',
              'rating': '4.9',
              'verified': true,
            },
          },
        ],
      }),
    );
    final repository = ApiServiceRepository(
      testDio(adapter),
      const ApiErrorMapper(),
    );
    final services = await repository.search(
      query: 'fuga',
      categorySlug: 'plomeria',
    );
    expect(services.single.professional?.name, 'Luis');
    expect(adapter.requests.single.queryParameters['q'], 'fuga');
    expect(adapter.requests.single.queryParameters['category'], 'plomeria');
  });

  test(
    'ProfessionalRepository no requiere ni parsea datos de contacto',
    () async {
      final adapter = DioTestAdapter(
        (_) => jsonResponse({
          'data': {
            'id': 3,
            'name': 'Luis',
            'rating': '4.8',
            'total_reviews': 10,
            'completed_jobs': 20,
            'verified': true,
            'phone': '5555555555',
            'email': 'private@example.test',
          },
        }),
      );
      final repository = ApiProfessionalRepository(
        testDio(adapter),
        const ApiErrorMapper(),
      );
      final professional = await repository.getProfessional(3);
      expect(professional.name, 'Luis');
      expect(professional.toString(), isNot(contains('private@example.test')));
      expect(professional.toString(), isNot(contains('5555555555')));
    },
  );
}
