import 'package:chambapp_mobile/app/providers.dart';
import 'package:chambapp_mobile/core/errors/api_error_mapper.dart';
import 'package:chambapp_mobile/features/catalog/domain/catalog_models.dart';
import 'package:chambapp_mobile/features/favorites/data/favorite_repository_impl.dart';
import 'package:chambapp_mobile/features/favorites/domain/favorite_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final favoriteRepositoryProvider = Provider<FavoriteRepository>(
  (ref) =>
      ApiFavoriteRepository(ref.watch(dioProvider), const ApiErrorMapper()),
);

final favoriteControllerProvider =
    AsyncNotifierProvider<FavoriteController, List<ProfessionalModel>>(
      FavoriteController.new,
    );

final class FavoriteController extends AsyncNotifier<List<ProfessionalModel>> {
  @override
  Future<List<ProfessionalModel>> build() {
    final userId = ref.watch(
      authControllerProvider.select((state) => state.user?.id),
    );
    if (userId == null) return Future.value(const []);
    return ref.watch(favoriteRepositoryProvider).getFavorites();
  }

  bool contains(int professionalId) =>
      state.value?.any((professional) => professional.id == professionalId) ??
      false;

  Future<bool> toggle(ProfessionalModel professional) async {
    if (state.isLoading) return contains(professional.id);
    final wasFavorite = contains(professional.id);
    final previous = state.value ?? const <ProfessionalModel>[];
    state = AsyncData(
      wasFavorite
          ? previous.where((item) => item.id != professional.id).toList()
          : [...previous, professional],
    );
    try {
      if (wasFavorite) {
        await ref.read(favoriteRepositoryProvider).remove(professional.id);
      } else {
        await ref.read(favoriteRepositoryProvider).add(professional.id);
      }
      return !wasFavorite;
    } catch (error, stack) {
      state = AsyncData(previous);
      state = AsyncError(error, stack);
      rethrow;
    }
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      ref.read(favoriteRepositoryProvider).getFavorites,
    );
  }
}
