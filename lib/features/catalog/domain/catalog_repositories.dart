import 'package:chambapp_mobile/features/catalog/domain/catalog_models.dart';

abstract interface class CategoryRepository {
  Future<List<CategoryModel>> getCategories();
}

abstract interface class ServiceRepository {
  Future<List<ServiceModel>> search({
    String? query,
    String? categorySlug,
    int page = 1,
  });
  Future<ServiceModel> getService(int id);
}

abstract interface class ProfessionalRepository {
  Future<ProfessionalModel> getProfessional(int id);
  Future<List<ReviewModel>> getReviews(int professionalId, {int page = 1});
}
