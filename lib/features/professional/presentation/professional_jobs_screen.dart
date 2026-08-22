import 'dart:async';

import 'package:chambapp_mobile/core/theme/app_tokens.dart';
import 'package:chambapp_mobile/features/jobs/domain/job_models.dart';
import 'package:chambapp_mobile/features/jobs/presentation/widgets/job_card.dart';
import 'package:chambapp_mobile/features/professional/domain/professional_models.dart';
import 'package:chambapp_mobile/features/professional/presentation/professional_providers.dart';
import 'package:chambapp_mobile/features/professional/presentation/widgets/invitation_card.dart';
import 'package:chambapp_mobile/shared/widgets/error_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class ProfessionalJobsScreen extends ConsumerStatefulWidget {
  const ProfessionalJobsScreen({super.key});
  @override
  ConsumerState<ProfessionalJobsScreen> createState() =>
      _ProfessionalJobsScreenState();
}

class _ProfessionalJobsScreenState extends ConsumerState<ProfessionalJobsScreen>
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
    if (mounted) _schedulePollingWithBackoff();
  }

  void _schedulePollingWithBackoff() {
    _pollTimer?.cancel();
    final errors =
        ref.read(jobInvitationsProvider).value?.consecutiveErrors ?? 0;
    final seconds = errors >= 3
        ? 30
        : (errors == 2 ? 20 : (errors == 1 ? 12 : 8));
    _pollTimer = Timer(Duration(seconds: seconds), _poll);
  }

  @override
  Widget build(BuildContext context) {
    final invitations = ref.watch(jobInvitationsProvider);
    final jobs = ref.watch(professionalJobsProvider(null));
    final availability = ref.watch(availabilityProvider).value;
    return Scaffold(
      appBar: AppBar(title: const Text('Mis chambas')),
      body: SafeArea(
        top: false,
        child: jobs.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => ErrorState(
            title: 'No pudimos cargar tus chambas',
            message: error,
            onRetry: () => ref.invalidate(professionalJobsProvider(null)),
          ),
          data: (items) => RefreshIndicator(
            onRefresh: _refreshAll,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                Text(
                  'Oportunidades',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: AppSpacing.sm),
                if (availability?.displayStatus == AvailabilityStatus.busy)
                  const Card(
                    child: ListTile(
                      leading: Icon(Icons.schedule, color: AppColors.amberDark),
                      title: Text('Ya tienes una chamba activa.'),
                      subtitle: Text('Tus trabajos activos aparecen debajo.'),
                    ),
                  )
                else if (availability?.isAvailable != true)
                  const Card(
                    child: ListTile(
                      leading: Icon(Icons.pause_circle_outline),
                      title: Text(
                        'Activa tu disponibilidad para recibir oportunidades.',
                      ),
                    ),
                  )
                else
                  invitations.when(
                    loading: () => const LinearProgressIndicator(),
                    error: (error, _) => ErrorState(
                      title: 'No pudimos cargar oportunidades',
                      message: error,
                      onRetry: () =>
                          ref.read(jobInvitationsProvider.notifier).refresh(),
                    ),
                    data: (feed) => Column(
                      children: [
                        if (feed.message != null)
                          Card(
                            color: AppColors.amber.withValues(alpha: .1),
                            child: ListTile(
                              title: Text(feed.message!),
                              trailing: TextButton(
                                onPressed: _refreshAll,
                                child: const Text('Actualizar'),
                              ),
                            ),
                          ),
                        if (feed.items.isEmpty)
                          const _Empty(
                            text: 'No hay chambas cerca en este momento.',
                          )
                        else
                          ...feed.items.map(
                            (invitation) => InvitationCard(
                              invitation: invitation,
                              processing: feed.processingIds.contains(
                                invitation.id,
                              ),
                              onAccept: () => _accept(invitation),
                              onDecline: () => _decline(invitation),
                              onExpired: () => ref
                                  .read(jobInvitationsProvider.notifier)
                                  .refresh(silent: true),
                            ),
                          ),
                      ],
                    ),
                  ),
                const SizedBox(height: AppSpacing.lg),
                _JobSection(
                  title: 'Próximas',
                  jobs: items
                      .where(
                        (job) => {
                          JobStatus.pending,
                          JobStatus.matched,
                          JobStatus.awaitingQuote,
                          JobStatus.accepted,
                          JobStatus.awaitingPayment,
                          JobStatus.paid,
                        }.contains(job.status),
                      )
                      .toList(),
                ),
                _JobSection(
                  title: 'Activas',
                  jobs: items
                      .where(
                        (job) => {
                          JobStatus.onTheWay,
                          JobStatus.arrived,
                          JobStatus.inProgress,
                          JobStatus.awaitingConfirmation,
                        }.contains(job.status),
                      )
                      .toList(),
                ),
                _JobSection(
                  title: 'Historial',
                  jobs: items
                      .where(
                        (job) => {
                          JobStatus.completed,
                          JobStatus.cancelled,
                          JobStatus.expired,
                          JobStatus.rejected,
                          JobStatus.disputed,
                        }.contains(job.status),
                      )
                      .toList(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _refreshAll() async {
    await ref.read(jobInvitationsProvider.notifier).refresh();
    ref.invalidate(professionalJobsProvider(null));
    await ref.read(professionalJobsProvider(null).future);
  }

  Future<void> _accept(JobInvitationModel invitation) async {
    final result = await ref
        .read(jobInvitationsProvider.notifier)
        .accept(invitation);
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(result.message)));
    if (result.succeeded && result.job != null) {
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          icon: const Icon(
            Icons.celebration,
            color: AppColors.success,
            size: 48,
          ),
          title: const Text('¡La chamba es tuya!'),
          content: const Text(
            'El servidor confirmó que eres el profesional asignado.',
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Ver detalle'),
            ),
          ],
        ),
      );
      if (mounted) context.push('/jobs/${result.job!.id}');
    }
  }

  Future<void> _decline(JobInvitationModel invitation) async {
    final result = await ref
        .read(jobInvitationsProvider.notifier)
        .decline(invitation);
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(result.message)));
    }
  }
}

class _JobSection extends StatelessWidget {
  const _JobSection({required this.title, required this.jobs});
  final String title;
  final List<JobModel> jobs;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(title, style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: AppSpacing.sm),
      if (jobs.isEmpty)
        const _Empty(text: 'No tienes chambas en esta sección.')
      else
        ...jobs.map(
          (job) => Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: JobCard(
              job: job,
              onTap: () => context.push('/jobs/${job.id}'),
            ),
          ),
        ),
      const SizedBox(height: AppSpacing.lg),
    ],
  );
}

class _Empty extends StatelessWidget {
  const _Empty({required this.text});
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
    child: Text(text),
  );
}
