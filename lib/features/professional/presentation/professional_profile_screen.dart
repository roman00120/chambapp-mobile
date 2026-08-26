import 'package:chambapp_mobile/app/providers.dart';
import 'package:chambapp_mobile/core/theme/app_tokens.dart';
import 'package:chambapp_mobile/features/notifications/presentation/notification_bell.dart';
import 'package:chambapp_mobile/features/professional/domain/professional_models.dart';
import 'package:chambapp_mobile/features/professional/presentation/professional_providers.dart';
import 'package:chambapp_mobile/shared/widgets/error_state.dart';
import 'package:chambapp_mobile/shared/widgets/primary_button.dart';
import 'package:chambapp_mobile/shared/widgets/remote_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class ProfessionalProfileScreen extends ConsumerWidget {
  const ProfessionalProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(professionalProfileProvider);
    final auth = ref.watch(authControllerProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil profesional'),
        actions: [
          const NotificationBell(),
          IconButton(
            tooltip: 'Editar perfil',
            onPressed: profile.value == null
                ? null
                : () => context.push('/professional/profile/edit'),
            icon: const Icon(Icons.edit_outlined),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: profile.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => ErrorState(
            title: 'No pudimos cargar tu perfil',
            message: error,
            onRetry: () => ref.invalidate(professionalProfileProvider),
          ),
          data: (value) => RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(professionalProfileProvider);
              await ref.read(professionalProfileProvider.future);
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                Center(
                  child: ClipOval(
                    child: RemoteImage(
                      url: value.avatarUrl,
                      width: 104,
                      height: 104,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  value.name,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: AppSpacing.sm),
                Center(child: _VerificationBadge(value.verification)),
                if (value.generalLocation.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(value.generalLocation, textAlign: TextAlign.center),
                ],
                const SizedBox(height: AppSpacing.lg),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Acerca de mí',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          value.bio?.isNotEmpty == true
                              ? value.bio!
                              : 'Aún no agregas una descripción profesional.',
                        ),
                        const Divider(height: AppSpacing.lg),
                        Text(
                          '${value.experienceYears ?? 0} años de experiencia',
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    _Stat(
                      label: 'Rating',
                      value: value.rating.toStringAsFixed(1),
                    ),
                    _Stat(label: 'Reseñas', value: '${value.totalReviews}'),
                    _Stat(
                      label: 'Completadas',
                      value: '${value.completedJobs}',
                    ),
                    _Stat(
                      label: 'Radio',
                      value: '${value.serviceRadiusKm ?? 10} km',
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                if (value.totalReviews == 0)
                  const Card(
                    child: ListTile(title: Text('Aún no tienes reseñas.')),
                  )
                else
                  OutlinedButton.icon(
                    onPressed: () =>
                        context.push('/professionals/${value.id}/reviews'),
                    icon: const Icon(Icons.star_outline),
                    label: const Text('Ver mis reseñas'),
                  ),
                if (value.achievements.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    'Reconocimientos y Medallas',
                    style: Theme.of(context).textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  ...value.achievements.map(
                    (ach) => Card(
                      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: ListTile(
                        leading: const Icon(
                          Icons.military_tech,
                          color: AppColors.amberDark,
                          size: 32,
                        ),
                        title: Text(
                          ach.name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(ach.description),
                        trailing: Chip(
                          label: Text(
                            ach.levelLabel,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          backgroundColor: AppColors.amber.withValues(
                            alpha: 0.2,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
                if (value.bio?.isNotEmpty != true ||
                    value.generalLocation.isEmpty) ...[
                  const SizedBox(height: AppSpacing.lg),
                  Card(
                    color: AppColors.amber.withValues(alpha: .12),
                    child: const Padding(
                      padding: EdgeInsets.all(AppSpacing.md),
                      child: Text(
                        'Completa tu perfil para generar más confianza.',
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.lg),
                FilledButton.icon(
                  onPressed: () => context.push('/professional/profile/edit'),
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Editar perfil'),
                ),
                const SizedBox(height: AppSpacing.md),
                OutlinedButton.icon(
                  onPressed: () => context.push('/security'),
                  icon: const Icon(Icons.shield_outlined),
                  label: const Text('Seguridad y Reportes'),
                ),
                if (auth.user?.canActAsClient == true) ...[
                  const SizedBox(height: AppSpacing.md),
                  OutlinedButton.icon(
                    onPressed: () {
                      ref
                          .read(authControllerProvider.notifier)
                          .switchActiveMode('client');
                      context.go('/client/home');
                    },
                    icon: const Icon(Icons.swap_horiz),
                    label: const Text('Cambiar a modo cliente'),
                  ),
                ],
                if (auth.user?.isAdmin == true) ...[
                  const SizedBox(height: AppSpacing.md),
                  OutlinedButton.icon(
                    onPressed: () => context.go('/admin/home'),
                    icon: const Icon(Icons.shield_outlined),
                    label: const Text('Panel de administración'),
                  ),
                ],
                const SizedBox(height: AppSpacing.md),
                PrimaryButton(
                  key: const Key('logout_button'),
                  label: 'Cerrar sesión',
                  isLoading: auth.isSubmitting,
                  onPressed: ref.read(authControllerProvider.notifier).logout,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _VerificationBadge extends StatelessWidget {
  const _VerificationBadge(this.status);
  final ProfessionalVerification status;
  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      ProfessionalVerification.verified => AppColors.success,
      ProfessionalVerification.pending => AppColors.amberDark,
      ProfessionalVerification.rejected => AppColors.danger,
      _ => AppColors.muted,
    };
    return Chip(
      avatar: Icon(
        status == ProfessionalVerification.verified
            ? Icons.verified
            : Icons.badge_outlined,
        color: color,
        size: 19,
      ),
      label: Text(status.label),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Container(
    width: 142,
    padding: const EdgeInsets.all(AppSpacing.md),
    decoration: BoxDecoration(
      color: AppColors.navy.withValues(alpha: .06),
      borderRadius: BorderRadius.circular(AppRadii.input),
    ),
    child: Column(
      children: [
        Text(value, style: Theme.of(context).textTheme.titleMedium),
        Text(label),
      ],
    ),
  );
}
