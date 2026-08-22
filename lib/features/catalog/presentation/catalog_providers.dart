import 'package:chambapp_mobile/app/providers.dart';
import 'package:chambapp_mobile/core/errors/api_error_mapper.dart';
import 'package:chambapp_mobile/features/catalog/data/catalog_repositories_impl.dart';
import 'package:chambapp_mobile/features/catalog/domain/catalog_models.dart';
import 'package:chambapp_mobile/features/catalog/domain/catalog_repositories.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final categoryRepositoryProvider = Provider<CategoryRepository>(
  (ref) =>
      ApiCategoryRepository(ref.watch(dioProvider), const ApiErrorMapper()),
);
final serviceRepositoryProvider = Provider<ServiceRepository>(
  (ref) => ApiServiceRepository(ref.watch(dioProvider), const ApiErrorMapper()),
);
final professionalRepositoryProvider = Provider<ProfessionalRepository>(
  (ref) =>
      ApiProfessionalRepository(ref.watch(dioProvider), const ApiErrorMapper()),
);

final categoriesProvider = FutureProvider<List<CategoryModel>>(
  (ref) => ref.watch(categoryRepositoryProvider).getCategories(),
);

final class ServiceSearchQuery {
  const ServiceSearchQuery({this.query, this.categorySlug});
  final String? query;
  final String? categorySlug;

  @override
  bool operator ==(Object other) =>
      other is ServiceSearchQuery &&
      other.query == query &&
      other.categorySlug == categorySlug;

  @override
  int get hashCode => Object.hash(query, categorySlug);
}

final servicesProvider =
    FutureProvider.family<List<ServiceModel>, ServiceSearchQuery>(
      (ref, input) => ref
          .watch(serviceRepositoryProvider)
          .search(query: input.query, categorySlug: input.categorySlug),
    );

final serviceDetailProvider = FutureProvider.family<ServiceModel, int>(
  (ref, id) => ref.watch(serviceRepositoryProvider).getService(id),
);
final professionalDetailProvider =
    FutureProvider.family<ProfessionalModel, int>(
      (ref, id) =>
          ref.watch(professionalRepositoryProvider).getProfessional(id),
    );
