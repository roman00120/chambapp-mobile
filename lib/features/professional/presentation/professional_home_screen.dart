import 'dart:async';

import 'package:chambapp_mobile/app/providers.dart';
import 'package:chambapp_mobile/core/theme/app_tokens.dart';
import 'package:chambapp_mobile/features/location/presentation/location_controller.dart';
import 'package:chambapp_mobile/features/notifications/presentation/notification_bell.dart';
import 'package:chambapp_mobile/features/professional/domain/professional_models.dart';
import 'package:chambapp_mobile/features/professional/presentation/professional_providers.dart';
import 'package:chambapp_mobile/features/professional/presentation/widgets/availability_card.dart';
import 'package:chambapp_mobile/features/professional/presentation/widgets/invitation_card.dart';
import 'package:chambapp_mobile/shared/widgets/error_state.dart';
import 'package:chambapp_mobile/shared/widgets/remote_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class ProfessionalHomeScreen extends ConsumerStatefulWidget {
  const ProfessionalHomeScreen({super.key});

  @override
  ConsumerState<ProfessionalHomeScreen> createState() =>
      _ProfessionalHomeScreenState();
}

class _ProfessionalHomeScreenState extends ConsumerState<ProfessionalHomeScreen>
    with WidgetsBindingObserver {
  Timer? _pollTimer;
  bool _foreground = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _schedulePolling());
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    if (_foreground) {
      ref.read(jobInvitationsProvider.notifier).refresh(silent: true);
      _schedulePolling();
    } else {
      _pollTimer?.cancel();
    }
  }

  void _schedulePolling() {
    _pollTimer?.cancel();
    if (!_foreground) return;
    _pollTimer = Timer(const Duration(seconds: 8), _poll);
  }

  Future<void> _poll() async {
    if (!mounted || !TickerMode.valuesOf(context).enabled) {
      _schedulePolling();
      return;
    }
    final availability = ref.read(availabilityProvider).value;
    if (availability?.displayStatus == AvailabilityStatus.available) {
      await ref.read(jobInvitationsProvider.notifier).refresh(silent: true);
    }
    if (mounted) _schedulePolling();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authControllerProvider).user!;
    final profile = ref.watch(professionalProfileProvider);
    final availability = ref.watch(availabilityProvider);
    final services = ref.watch(professionalServicesProvider);
    final invitations = ref.watch(jobInvitationsProvider);
    final jobs = ref.watch(professionalJobsProvider(null));

    Future<void> refresh() async {
      ref.invalidate(professionalProfileProvider);
      ref.invalidate(availabilityProvider);
      ref.invalidate(professionalServicesProvider);
      ref.invalidate(jobInvitationsProvider);
      ref.invalidate(professionalJobsProvider(null));
      await Future.wait([
        ref.read(professionalProfileProvider.future),
        ref.read(availabilityProvider.future),
      ]);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chambapp Profesional'),
        actions: const [NotificationBell()],
      ),
      body: SafeArea(
        top: false,
        child: RefreshIndicator(
          onRefresh: refresh,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              profile.when(
                loading: () => _Header(name: user.name),
                error: (_, _) => _Header(name: user.name),
                data: (value) =>
                    _Header(name: value.name, avatarUrl: value.avatarUrl),
              ),
              const SizedBox(height: AppSpacing.md),
              availability.when(
                loading: () => const Card(
                  child: Padding(
                    padding: EdgeInsets.all(AppSpacing.lg),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ),
                error: (error, _) => ErrorState(
                  title: 'No pudimos consultar tu disponibilidad',
                  message: error,
                  onRetry: () => ref.invalidate(availabilityProvider),
                ),
                data: (value) => AvailabilityCard(
                  availability: value,
                  loading: availability.isLoading,
                  onChanged: (enabled) => _toggle(context, ref, value, enabled),
                  onManage: () => context.push('/professional/availability'),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Acciones rápidas',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: _QuickAction(
                      icon: Icons.add_business,
                      label: 'Crear servicio',
                      onTap: () => context.push('/professional/services/new'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: _QuickAction(
                      icon: Icons.my_location,
                      label: 'Ubicación',
                      onTap: () => context.push('/professional/availability'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              _SectionTitle(
                title: 'Chambas cerca de ti',
                action: 'Ver todas',
                onTap: () => context.go('/professional/jobs'),
              ),
              invitations.when(
                loading: () => const LinearProgressIndicator(),
                error: (error, _) =>
                    const Text('No pudimos cargar las oportunidades.'),
                data: (feed) => feed.items.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.md,
                        ),
                        child: Text(
                          availability.value?.isAvailable == true
                              ? 'No hay chambas cerca en este momento.'
                              : 'Activa tu disponibilidad para recibir oportunidades.',
                        ),
                      )
                    : Column(
                        children: feed.items
                            .take(3)
                            .map(
                              (invitation) => InvitationCard(
                                invitation: invitation,
                                compact: true,
                                processing: feed.processingIds.contains(
                                  invitation.id,
                                ),
                                onAccept: () =>
                                    _accept(context, ref, invitation),
                                onDecline: () =>
                                    _decline(context, ref, invitation),
                                onExpired: () => ref
                                    .read(jobInvitationsProvider.notifier)
                                    .refresh(silent: true),
                              ),
                            )
                            .toList(),
                      ),
              ),
              const SizedBox(height: AppSpacing.lg),
              _SectionTitle(
                title: 'Próximos trabajos',
                action: 'Mis chambas',
                onTap: () => context.go('/professional/jobs'),
              ),
              jobs.when(
                loading: () => const LinearProgressIndicator(),
                error: (error, _) =>
                    const Text('No pudimos cargar los trabajos.'),
                data: (items) {
                  final active = items
                      .where((job) => job.status.active)
                      .take(3);
                  return active.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.symmetric(
                            vertical: AppSpacing.md,
                          ),
                          child: Text('No tienes trabajos próximos o activos.'),
                        )
                      : Column(
                          children: active
                              .map(
                                (job) => ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: const CircleAvatar(
                                    child: Icon(Icons.work_outline),
                                  ),
                                  title: Text(job.category?.name ?? job.title),
                                  subtitle: Text(job.statusLabel),
                                  trailing: const Icon(Icons.chevron_right),
                                  onTap: () => context.push('/jobs/${job.id}'),
                                ),
                              )
                              .toList(),
                        );
                },
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Resumen profesional',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.sm),
              profile.when(
                loading: () => const LinearProgressIndicator(),
                error: (error, _) =>
                    const Text('No pudimos cargar este resumen.'),
                data: (value) => Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    _Metric(
                      label: 'Rating',
                      value: value.rating.toStringAsFixed(1),
                    ),
                    _Metric(
                      label: 'Completadas',
                      value: '${value.completedJobs}',
                    ),
                    _Metric(
                      label: 'Servicios activos',
                      value:
                          '${services.value?.where((item) => item.isActive).length ?? 0}',
                    ),
                    _Metric(
                      label: 'Verificación',
                      value: value.verification.label,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _toggle(
    BuildContext context,
    WidgetRef ref,
    AvailabilityModel current,
    bool enabled,
  ) async {
    double? latitude;
    double? longitude;
    if (enabled && (current.latitude == null || current.longitude == null)) {
      await ref.read(locationControllerProvider.notifier).detect();
      final position = ref.read(locationControllerProvider).position;
      if (position == null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                ref.read(locationControllerProvider).message ??
                    'Actualiza tu ubicación antes de ponerte disponible.',
              ),
            ),
          );
        }
        return;
      }
      latitude = position.latitude;
      longitude = position.longitude;
    }
    final ok = await ref
        .read(availabilityProvider.notifier)
        .saveAvailability(
          isAvailable: enabled,
          serviceRadiusKm: current.serviceRadiusKm,
          latitude: latitude,
          longitude: longitude,
        );
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No pudimos actualizar tu disponibilidad.'),
        ),
      );
    }
  }

  Future<void> _accept(
    BuildContext context,
    WidgetRef ref,
    JobInvitationModel invitation,
  ) async {
    final result = await ref
        .read(jobInvitationsProvider.notifier)
        .accept(invitation);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(result.message)));
    if (result.succeeded && result.job != null) {
      context.push('/jobs/${result.job!.id}');
    }
  }

  Future<void> _decline(
    BuildContext context,
    WidgetRef ref,
    JobInvitationModel invitation,
  ) async {
    final result = await ref
        .read(jobInvitationsProvider.notifier)
        .decline(invitation);
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(result.message)));
    }
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.name, this.avatarUrl});
  final String name;
  final String? avatarUrl;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      ClipOval(child: RemoteImage(url: avatarUrl, width: 56, height: 56)),
      const SizedBox(width: AppSpacing.md),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hola, ${name.trim().split(RegExp(r'\s+')).first}',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const Text('¿Listo para una nueva chamba?'),
          ],
        ),
      ),
    ],
  );
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Card(
    child: InkWell(
      borderRadius: BorderRadius.circular(AppRadii.card),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          children: [Icon(icon), const SizedBox(height: 6), Text(label)],
        ),
      ),
    ),
  );
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.title,
    required this.action,
    required this.onTap,
  });
  final String title;
  final String action;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(title, style: Theme.of(context).textTheme.titleLarge),
      ),
      TextButton(onPressed: onTap, child: Text(action)),
    ],
  );
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(minWidth: 140),
    padding: const EdgeInsets.all(AppSpacing.md),
    decoration: BoxDecoration(
      color: AppColors.navy.withValues(alpha: .06),
      borderRadius: BorderRadius.circular(AppRadii.input),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value, style: Theme.of(context).textTheme.titleMedium),
        Text(label),
      ],
    ),
  );
}
