import 'package:chambapp_mobile/features/catalog/domain/catalog_models.dart';

abstract interface class FavoriteRepository {
  Future<List<ProfessionalModel>> getFavorites();
  Future<void> add(int professionalId);
  Future<void> remove(int professionalId);
}
