import 'package:chambapp_mobile/core/theme/app_tokens.dart';
import 'package:chambapp_mobile/features/favorites/presentation/favorite_controller.dart';
import 'package:chambapp_mobile/shared/widgets/app_feedback.dart';
import 'package:chambapp_mobile/shared/widgets/error_state.dart';
import 'package:chambapp_mobile/shared/widgets/remote_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favorites = ref.watch(favoriteControllerProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Favoritos')),
      body: SafeArea(
        top: false,
        child: favorites.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => ErrorState(
            title: 'No pudimos cargar tus favoritos',
            message: error,
            onRetry: ref.read(favoriteControllerProvider.notifier).refresh,
          ),
          data: (items) => items.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Aún no guardas profesionales.'),
                        const SizedBox(height: AppSpacing.md),
                        FilledButton(
                          onPressed: () => context.go('/client/search'),
                          child: const Text('Buscar profesionales'),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: ref
                      .read(favoriteControllerProvider.notifier)
                      .refresh,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    itemCount: items.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (context, index) {
                      final professional = items[index];
                      return Card(
                        child: ListTile(
                          onTap: () =>
                              context.push('/professionals/${professional.id}'),
                          leading: RemoteImage(
                            url: professional.avatarUrl,
                            width: 50,
                            height: 50,
                            borderRadius: BorderRadius.circular(25),
                          ),
                          title: Text(professional.name),
                          subtitle: Text(
                            '★ ${professional.rating.toStringAsFixed(1)} · ${professional.generalLocation}',
                          ),
                          trailing: IconButton(
                            tooltip: 'Quitar de favoritos',
                            onPressed: () async {
                              try {
                                await ref
                                    .read(favoriteControllerProvider.notifier)
                                    .toggle(professional);
                                if (context.mounted) {
                                  AppFeedback.show(
                                    context,
                                    'Se eliminó de favoritos.',
                                    type: FeedbackType.success,
                                  );
                                }
                              } catch (error) {
                                if (context.mounted) {
                                  AppFeedback.show(context, '$error');
                                }
                              }
                            },
                            icon: const Icon(
                              Icons.favorite,
                              color: AppColors.danger,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
        ),
      ),
    );
  }
}
