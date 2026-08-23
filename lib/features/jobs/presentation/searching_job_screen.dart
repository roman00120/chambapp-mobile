import 'dart:async';

import 'package:chambapp_mobile/core/theme/app_tokens.dart';
import 'package:chambapp_mobile/features/catalog/domain/catalog_models.dart';
import 'package:chambapp_mobile/features/jobs/domain/job_models.dart';
import 'package:chambapp_mobile/features/jobs/presentation/job_providers.dart';
import 'package:chambapp_mobile/shared/widgets/primary_button.dart';
import 'package:chambapp_mobile/shared/widgets/remote_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class SearchingJobScreen extends ConsumerStatefulWidget {
  const SearchingJobScreen({required this.jobId, this.initialJob, super.key});
  final int jobId;
  final JobModel? initialJob;

  @override
  ConsumerState<SearchingJobScreen> createState() => _SearchingJobScreenState();
}

class _SearchingJobScreenState extends ConsumerState<SearchingJobScreen>
    with WidgetsBindingObserver {
  Timer? _timer;
  Timer? _elapsedTimer;
  JobStatusModel? _status;
  bool _polling = false;
  String? _error;
  int _consecutiveErrors = 0;
  late final DateTime _startedAt;
  bool _foreground = true;

  @override
  void initState() {
    super.initState();
    _startedAt = DateTime.now();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _poll();
    });
    _elapsedTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && _foreground) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _elapsedTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    if (_foreground) {
      _poll();
    } else {
      _timer?.cancel();
    }
  }

  void _scheduleNext() {
    _timer?.cancel();
    if (!_foreground || !_shouldPoll) return;
    final status = _status?.status ?? widget.initialJob?.status;
    final seconds = status == JobStatus.matched
        ? 10
        : _consecutiveErrors >= 3
        ? 30
        : 5 * (1 << _consecutiveErrors.clamp(0, 2));
    _timer = Timer(Duration(seconds: seconds), _poll);
  }

  bool get _shouldPoll =>
      {JobStatus.searching, JobStatus.matched, JobStatus.unknown}.contains(
        _status?.status ?? widget.initialJob?.status ?? JobStatus.searching,
      );

  Future<void> _poll() async {
    if (_polling || !mounted || !_foreground) return;
    if (!TickerMode.valuesOf(context).enabled) {
      _scheduleNext();
      return;
    }
    _polling = true;
    try {
      final status = await ref
          .read(jobRepositoryProvider)
          .getStatus(widget.jobId);
      if (!mounted) return;
      setState(() {
        _status = status;
        _error = null;
        _consecutiveErrors = 0;
      });
    } catch (error) {
      if (mounted) {
        setState(() {
          _consecutiveErrors++;
          _error = 'Perdiste conexión. Intentaremos actualizar cuando vuelva.';
        });
      }
    } finally {
      _polling = false;
      if (mounted) _scheduleNext();
    }
  }

  @override
  Widget build(BuildContext context) {
    final status =
        _status?.status ?? widget.initialJob?.status ?? JobStatus.searching;
    return Scaffold(
      appBar: AppBar(title: const Text('Estado de tu chamba')),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _poll,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              if (_error != null)
                Card(
                  color: AppColors.danger.withValues(alpha: .08),
                  child: ListTile(
                    title: const Text('No pudimos actualizar el estado'),
                    subtitle: Text(_error!),
                    trailing: TextButton(
                      onPressed: _poll,
                      child: const Text('Reintentar'),
                    ),
                  ),
                ),
              _StatusContent(
                status: status,
                professional:
                    _status?.professional ?? widget.initialJob?.professional,
                job: widget.initialJob,
                elapsed: DateTime.now().difference(_startedAt),
                onRetry: () => context.go('/request/immediate'),
                onSchedule: () => context.go('/request/scheduled'),
                onHome: () => context.go('/client/home'),
                onViewDetails: () => context.go('/jobs/${widget.jobId}'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusContent extends StatelessWidget {
  const _StatusContent({
    required this.status,
    required this.professional,
    required this.job,
    required this.elapsed,
    required this.onRetry,
    required this.onSchedule,
    required this.onHome,
    required this.onViewDetails,
  });
  final JobStatus status;
  final ProfessionalModel? professional;
  final JobModel? job;
  final Duration elapsed;
  final VoidCallback onRetry;
  final VoidCallback onSchedule;
  final VoidCallback onHome;
  final VoidCallback onViewDetails;

  @override
  Widget build(BuildContext context) {
    if (status == JobStatus.expired || status == JobStatus.cancelled) {
      return Column(
        key: const Key('job_expired'),
        children: [
          const SizedBox(height: AppSpacing.xxl),
          const Icon(Icons.search_off, size: 72, color: AppColors.muted),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'No encontramos profesionales disponibles cerca.',
            style: Theme.of(context).textTheme.headlineMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xl),
          PrimaryButton(label: 'Buscar nuevamente', onPressed: onRetry),
          const SizedBox(height: AppSpacing.sm),
          OutlinedButton(
            onPressed: onSchedule,
            child: const Text('Programar para después'),
          ),
          TextButton(onPressed: onHome, child: const Text('Volver al inicio')),
        ],
      );
    }
    if (status == JobStatus.matched) {
      return Column(
        key: const Key('job_matched'),
        children: [
          const Icon(Icons.verified, size: 64, color: AppColors.success),
          const SizedBox(height: AppSpacing.md),
          Text(
            '¡Encontramos un profesional!',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: AppSpacing.lg),
          if (professional != null)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Row(
                  children: [
                    RemoteImage(
                      url: professional!.avatarUrl,
                      width: 64,
                      height: 64,
                      borderRadius: BorderRadius.circular(32),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            professional!.name,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          Text(
                            '★ ${professional!.rating.toStringAsFixed(1)} · ${professional!.completedJobs} trabajos',
                          ),
                          if (professional!.verified)
                            const Text(
                              'Profesional verificado',
                              style: TextStyle(color: AppColors.success),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const Text(
            'Tu información de contacto y dirección exacta permanecen ocultas.',
          ),
        ],
      );
    }
    if (status == JobStatus.awaitingQuote) {
      return Column(
        key: const Key('job_awaiting_quote'),
        children: [
          const SizedBox(height: AppSpacing.xxl),
          const Icon(
            Icons.request_quote_outlined,
            size: 72,
            color: AppColors.amberDark,
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Tu profesional está preparando la cotización.',
            style: Theme.of(context).textTheme.headlineMedium,
            textAlign: TextAlign.center,
          ),
          if (professional != null) ...[
            const SizedBox(height: AppSpacing.lg),
            _ProfessionalSummary(professional!),
          ],
          const SizedBox(height: AppSpacing.lg),
          FilledButton(
            onPressed: onViewDetails,
            child: const Text('Ver cotización'),
          ),
        ],
      );
    }
    return Column(
      key: const Key('job_searching'),
      children: [
        const SizedBox(height: AppSpacing.xxl),
        const SizedBox.square(
          dimension: 88,
          child: CircularProgressIndicator(strokeWidth: 8),
        ),
        const SizedBox(height: AppSpacing.xl),
        Text(
          'Buscando profesional',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: AppSpacing.sm),
        const Text(
          'Buscando profesionales disponibles cerca de ti…',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text('Tiempo transcurrido: ${_elapsedLabel(elapsed)}'),
        if (job != null) ...[
          const SizedBox(height: AppSpacing.xl),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    job!.category?.name ?? job!.title,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  Text(
                    job!.description,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (job!.generalLocation.isNotEmpty)
                    Text(job!.generalLocation),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  String _elapsedLabel(Duration value) =>
      '${value.inMinutes}:${(value.inSeconds % 60).toString().padLeft(2, '0')}';
}

class _ProfessionalSummary extends StatelessWidget {
  const _ProfessionalSummary(this.professional);
  final ProfessionalModel professional;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        children: [
          RemoteImage(
            url: professional.avatarUrl,
            width: 64,
            height: 64,
            borderRadius: BorderRadius.circular(32),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  professional.name,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                Text(
                  '★ ${professional.rating.toStringAsFixed(1)} · ${professional.completedJobs} trabajos',
                ),
                if (professional.verified)
                  const Text(
                    'Profesional verificado',
                    style: TextStyle(color: AppColors.success),
                  ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
