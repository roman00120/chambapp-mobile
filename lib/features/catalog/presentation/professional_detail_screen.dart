import 'package:chambapp_mobile/core/theme/app_tokens.dart';
import 'package:chambapp_mobile/features/catalog/presentation/catalog_providers.dart';
import 'package:chambapp_mobile/features/catalog/presentation/widgets/service_card.dart';
import 'package:chambapp_mobile/features/favorites/presentation/favorite_controller.dart';
import 'package:chambapp_mobile/shared/widgets/app_feedback.dart';
import 'package:chambapp_mobile/shared/widgets/error_state.dart';
import 'package:chambapp_mobile/shared/widgets/remote_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class ProfessionalDetailScreen extends ConsumerWidget {
  const ProfessionalDetailScreen({required this.professionalId, super.key});
  final int professionalId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(professionalDetailProvider(professionalId));
    final favorites = ref.watch(favoriteControllerProvider);
    final isFavorite =
        favorites.value?.any((item) => item.id == professionalId) ?? false;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profesional'),
        actions: [
          IconButton(
            tooltip: isFavorite ? 'Quitar de favoritos' : 'Guardar profesional',
            onPressed: detail.value == null
                ? null
                : () async {
                    try {
                      final added = await ref
                          .read(favoriteControllerProvider.notifier)
                          .toggle(detail.value!);
                      if (context.mounted) {
                        AppFeedback.show(
                          context,
                          added
                              ? 'Profesional guardado.'
                              : 'Se eliminó de favoritos.',
                          type: FeedbackType.success,
                        );
                      }
                    } catch (error) {
                      if (context.mounted) AppFeedback.show(context, '$error');
                    }
                  },
            icon: Icon(
              isFavorite ? Icons.favorite : Icons.favorite_outline,
              color: isFavorite ? AppColors.danger : null,
            ),
          ),
        ],
      ),
      body: detail.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => ErrorState(
          title: 'No pudimos cargar el perfil',
          message: error,
          onRetry: () =>
              ref.invalidate(professionalDetailProvider(professionalId)),
        ),
        data: (professional) => SafeArea(
          top: false,
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              Center(
                child: RemoteImage(
                  url: professional.avatarUrl,
                  width: 104,
                  height: 104,
                  borderRadius: BorderRadius.circular(52),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: Text(
                      professional.name,
                      style: Theme.of(context).textTheme.headlineMedium,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  if (professional.verified)
                    const Padding(
                      padding: EdgeInsets.only(left: 6),
                      child: Icon(Icons.verified, color: AppColors.success),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                '★ ${professional.rating.toStringAsFixed(1)} (${professional.totalReviews}) · ${professional.completedJobs} trabajos',
                textAlign: TextAlign.center,
              ),
              if (professional.generalLocation.isNotEmpty)
                Text(professional.generalLocation, textAlign: TextAlign.center),
              const SizedBox(height: AppSpacing.lg),
              if (professional.bio?.isNotEmpty == true)
                Text(
                  professional.bio!,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              if (professional.experienceYears != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Text('${professional.experienceYears} años de experiencia'),
              ],
              const SizedBox(height: AppSpacing.xl),
              Text('Servicios', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: AppSpacing.md),
              ...professional.services.map(
                (service) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: ServiceCard(
                    service: service,
                    onTap: () => context.push('/services/${service.id}'),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Reseñas recientes',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  TextButton(
                    onPressed: () =>
                        context.push('/professionals/$professionalId/reviews'),
                    child: const Text('Ver todas'),
                  ),
                ],
              ),
              if (professional.recentReviews.isEmpty)
                const Text('Aún no hay reseñas.')
              else ...[
                ...professional.recentReviews.map(
                  (review) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      '${review.clientName} · ${'★' * review.rating}',
                    ),
                    subtitle: Text(review.comment ?? ''),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
