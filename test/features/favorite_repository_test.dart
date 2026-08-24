import 'package:chambapp_mobile/core/errors/api_error_mapper.dart';
import 'package:chambapp_mobile/features/favorites/data/favorite_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/dio_test_adapter.dart';

void main() {
  test(
    'FavoriteRepository lista, agrega y elimina usando endpoints reales',
    () async {
      final adapter = DioTestAdapter(
        (options) => options.path == '/favorites'
            ? jsonResponse({
                'data': [
                  {
                    'id': 4,
                    'name': 'Ana Pro',
                    'rating': '5',
                    'identity_verified': true,
                  },
                ],
              })
            : jsonResponse({'data': null}),
      );
      final repository = ApiFavoriteRepository(
        testDio(adapter),
        const ApiErrorMapper(),
      );
      expect((await repository.getFavorites()).single.id, 4);
      await repository.add(4);
      await repository.remove(4);
      expect(adapter.requests.map((request) => request.method), [
        'GET',
        'POST',
        'DELETE',
      ]);
      expect(adapter.requests.last.path, '/favorites/4');
    },
  );
}
