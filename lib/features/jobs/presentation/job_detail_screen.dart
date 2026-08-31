import 'dart:async';

import 'package:chambapp_mobile/app/providers.dart';
import 'package:chambapp_mobile/core/errors/app_exception.dart';
import 'package:chambapp_mobile/core/theme/app_tokens.dart';
import 'package:chambapp_mobile/features/auth/domain/user.dart';
import 'package:chambapp_mobile/features/catalog/domain/catalog_models.dart';
import 'package:chambapp_mobile/features/jobs/domain/job_models.dart';
import 'package:chambapp_mobile/features/jobs/domain/job_workflow.dart';
import 'package:chambapp_mobile/features/jobs/presentation/job_providers.dart';
import 'package:chambapp_mobile/shared/widgets/error_state.dart';
import 'package:chambapp_mobile/shared/widgets/remote_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

class JobDetailScreen extends ConsumerStatefulWidget {
  const JobDetailScreen({
    required this.jobId,
    this.createdScheduled = false,
    super.key,
  });
  final int jobId;
  final bool createdScheduled;

  @override
  ConsumerState<JobDetailScreen> createState() => _JobDetailScreenState();
}

class _JobDetailScreenState extends ConsumerState<JobDetailScreen>
    with WidgetsBindingObserver {
  Timer? _pollingTimer;
  AppLifecycleState _lifecycle = AppLifecycleState.resumed;
  JobModel? _lastJob;
  bool _refreshing = false;
  int? _processingQuote;
  JobWorkflowActionType? _processingAction;
  String? _actionMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _pollingTimer = Timer.periodic(
      const Duration(seconds: 7),
      (_) => unawaited(_pollIfNeeded()),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _lifecycle = state;
    if (state == AppLifecycleState.resumed) unawaited(_refresh());
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  bool get _isOperational => {
    JobStatus.paid,
    JobStatus.onTheWay,
    JobStatus.arrived,
    JobStatus.inProgress,
    JobStatus.awaitingConfirmation,
  }.contains(_lastJob?.status);

  Future<void> _pollIfNeeded() async {
    if (!mounted ||
        _lifecycle != AppLifecycleState.resumed ||
        ModalRoute.of(context)?.isCurrent != true ||
        !_isOperational) {
      return;
    }
    await _refresh();
  }

  Future<void> _refresh() async {
    if (_refreshing || !mounted) return;
    _refreshing = true;
    try {
      ref.invalidate(jobDetailProvider(widget.jobId));
      ref.invalidate(jobQuotesProvider(widget.jobId));
      await ref.read(jobDetailProvider(widget.jobId).future);
    } finally {
      _refreshing = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final detail = ref.watch(jobDetailProvider(widget.jobId));
    final quotes = ref.watch(jobQuotesProvider(widget.jobId));
    final currentUser = ref.watch(authControllerProvider).user;
    final effectiveRole = currentUser?.effectiveRole ?? currentUser?.role;
    final currentJob = detail.value;
    if (currentJob != null) _lastJob = currentJob;

    final isOwnerClient = currentJob != null &&
        currentUser != null &&
        currentJob.clientId != null &&
        currentJob.clientId == currentUser.id;

    final isAssignedPro = currentJob != null &&
        currentUser != null &&
        ((currentJob.professional?.userId != null && currentJob.professional!.userId == currentUser.id) ||
         (currentJob.service?.professional?.userId != null && currentJob.service!.professional!.userId == currentUser.id));

    final isClient = isOwnerClient ||
        (!isAssignedPro &&
            (currentUser?.activeMode == 'client' || effectiveRole == UserRole.client || effectiveRole == UserRole.admin));

    final isProfessional = isAssignedPro ||
        (!isOwnerClient &&
            (currentUser?.activeMode == 'professional' || effectiveRole == UserRole.professional));

    final primary = currentJob == null || currentUser == null
        ? null
        : JobWorkflowActions.primaryForJob(
            isClient: isClient,
            isProfessional: isProfessional,
            status: currentJob.status,
          );

    return Scaffold(
      appBar: AppBar(title: const Text('Detalle de chamba')),
      body: detail.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => ErrorState(
          title: 'No pudimos cargar la chamba',
          message: error,
          onRetry: _refresh,
        ),
        data: (job) => RefreshIndicator(
          onRefresh: _refresh,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg,
              primary == null ? AppSpacing.xl : 104,
            ),
            children: [
              if (widget.createdScheduled) const _SuccessNotice(),
              _StatusHeader(job: job, isClient: isClient, isProfessional: isProfessional),
              const SizedBox(height: AppSpacing.lg),
              Text(
                job.category?.name ?? job.title,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(job.description),
              const SizedBox(height: AppSpacing.lg),
              _Detail(label: 'Estado', value: job.status.label),
              _Detail(
                label: 'Modalidad',
                value: job.serviceMode == 'immediate' ? 'Ahora' : 'Programada',
              ),
              if (job.scheduledFor != null)
                _Detail(
                  label: 'Fecha',
                  value: _localDate(job.scheduledFor!, job.scheduledSlot),
                ),
              if (job.generalLocation.isNotEmpty)
                _Detail(label: 'Zona', value: job.generalLocation),
              if (job.agreedPrice != null)
                _Detail(
                  label: 'Precio acordado',
                  value: '\$${job.agreedPrice} ${job.currency ?? 'MXN'}',
                ),
              if (job.professional != null) _ProfessionalCard(job: job),
              if (job.address != null ||
                  (job.latitude != null && job.longitude != null))
                _OperationalData(job: job, onOpenMaps: () => _openMaps(job)),
              if (_actionMessage != null)
                Card(
                  color: AppColors.amber.withValues(alpha: .08),
                  child: ListTile(title: Text(_actionMessage!)),
                ),
              const SizedBox(height: AppSpacing.lg),
              if (isProfessional) _professionalContent(job),
              if (isClient) _clientContent(job, quotes),
              if (isProfessional && job.payment != null)
                _ProfessionalPayment(payment: job.payment!),
              const SizedBox(height: AppSpacing.xl),
              Text('Progreso', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: AppSpacing.md),
              _JobTimeline(job: job),
            ],
          ),
        ),
      ),
      bottomNavigationBar: primary == null || currentJob == null
          ? null
          : SafeArea(
              minimum: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.sm,
                AppSpacing.lg,
                AppSpacing.md,
              ),
              child: FilledButton(
                onPressed: _processingAction == null
                    ? () => _runWorkflow(currentJob, primary)
                    : null,
                child: Text(
                  _processingAction == primary.type
                      ? primary.loadingLabel
                      : primary.label,
                ),
              ),
            ),
    );
  }

  Widget _professionalContent(JobModel job) {
    final canQuote =
        job.service == null &&
        (job.status == JobStatus.matched ||
            job.status == JobStatus.accepted ||
            (job.status == JobStatus.awaitingQuote &&
                !job.quotes.any((quote) => quote.status == QuoteStatus.pending)));
    if (canQuote) {
      return FilledButton.icon(
        onPressed: () async {
          final quote = await context.push<JobQuoteModel>(
            '/jobs/${job.id}/quote',
          );
          if (quote != null && mounted) {
            setState(() => _actionMessage = 'Cotización enviada.');
            await _refresh();
          }
        },
        icon: const Icon(Icons.request_quote_outlined),
        label: Text(
          job.status == JobStatus.awaitingQuote
              ? 'Enviar nueva cotización'
              : 'Enviar cotización',
        ),
      );
    }
    return switch (job.status) {
      JobStatus.pending => job.service != null
          ? _StateCard(
              title: 'Nueva solicitud directa',
              body:
                  'Servicio: "${job.service!.title}" por \$${job.service!.price} MXN. Puedes aceptarla o rechazarla en la barra inferior.',
            )
          : const _StateCard(
              title: 'Solicitud pendiente',
              body: 'Esperando respuesta o asignación.',
            ),
      JobStatus.awaitingQuote => const _StateCard(
        title: 'Cotización enviada',
        body: 'Esperando respuesta del cliente.',
      ),
      JobStatus.awaitingPayment => const _StateCard(
        title: 'Solicitud aceptada',
        body: 'Esperando confirmación del pago del cliente.',
      ),
      JobStatus.awaitingConfirmation => const _StateCard(
        title: 'Esperando confirmación del cliente',
        body: 'El profesional no completa directamente la chamba.',
      ),
      JobStatus.completed => _StateCard(
        title: 'Chamba completada',
        body: job.review == null
            ? 'Aún no recibes una reseña.'
            : 'Recibiste ${job.review!.rating} de 5 estrellas.',
      ),
      JobStatus.disputed => const _StateCard(
        title: 'Reporte en revisión',
        body: 'Este trabajo tiene un reporte en revisión.',
      ),
      _ => const SizedBox.shrink(),
    };
  }

  Widget _clientContent(JobModel job, AsyncValue<List<JobQuoteModel>> quotes) {
    if (job.status == JobStatus.awaitingPayment) {
      return FilledButton.icon(
        onPressed: () => context.push('/jobs/${job.id}/checkout'),
        icon: const Icon(Icons.payment),
        label: const Text('Pagar Chamba'),
      );
    }
    if (job.status == JobStatus.awaitingConfirmation) {
      return Column(
        children: [
          const _StateCard(
            title: '¿El trabajo fue realizado correctamente?',
            body: 'Confirma el trabajo o reporta un problema a Chambapp.',
          ),
          OutlinedButton(
            style: OutlinedButton.styleFrom(foregroundColor: AppColors.danger),
            onPressed: _processingAction == null
                ? () async {
                    final result = await context.push<JobModel>(
                      '/jobs/${job.id}/dispute',
                    );
                    if (result != null && mounted) {
                      setState(
                        () =>
                            _actionMessage = 'Tu reporte está siendo revisado.',
                      );
                      await _refresh();
                    }
                  }
                : null,
            child: const Text('Reportar un problema'),
          ),
        ],
      );
    }
    if (job.status == JobStatus.completed) {
      return Column(
        children: [
          _StateCard(
            title: job.review == null
                ? 'Chamba completada'
                : 'Ya calificaste esta chamba',
            body: job.review == null
                ? 'Gracias por usar Chambapp.'
                : '${job.review!.rating} de 5 estrellas.',
          ),
          if (job.review == null && job.professional != null)
            FilledButton.icon(
              onPressed: () => _openReview(job),
              icon: const Icon(Icons.star_outline),
              label: const Text('Calificar profesional'),
            ),
          if (job.review != null)
            const Chip(
              avatar: Icon(Icons.check_circle_outline),
              label: Text('Calificado'),
            ),
          OutlinedButton(
            onPressed: () => context.go('/client/home'),
            child: const Text('Volver al inicio'),
          ),
        ],
      );
    }
    if (job.status == JobStatus.disputed) {
      return const _StateCard(
        title: 'Tu reporte está siendo revisado',
        body: 'Reportar un problema no genera un reembolso automático.',
      );
    }
    if ({
      JobStatus.paid,
      JobStatus.onTheWay,
      JobStatus.arrived,
      JobStatus.inProgress,
    }.contains(job.status)) {
      return const SizedBox.shrink();
    }
    if (job.status != JobStatus.awaitingQuote &&
        job.status != JobStatus.accepted) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Cotizaciones', style: Theme.of(context).textTheme.titleLarge),
        quotes.when(
          loading: () => const LinearProgressIndicator(),
          error: (error, _) => ErrorState(
            title: 'No pudimos consultar cotizaciones',
            message: error,
            onRetry: () => ref.invalidate(jobQuotesProvider(job.id)),
          ),
          data: (items) {
            final active = items
                .where((quote) => quote.status == QuoteStatus.pending)
                .toList();
            if (active.isEmpty) {
              return const _StateCard(
                title: 'Esperando cotización',
                body: 'El profesional está preparando su propuesta.',
              );
            }
            return Column(
              children: active
                  .map(
                    (quote) => _QuoteCard(
                      job: job,
                      quote: quote,
                      processing: _processingQuote == quote.id,
                      onAccept: () => _accept(job, quote),
                      onReject: () => _reject(job, quote),
                    ),
                  )
                  .toList(),
            );
          },
        ),
      ],
    );
  }

  Future<void> _openReview(JobModel job) async {
    final review = await context.push<ReviewModel>(
      '/jobs/${job.id}/review?professional=${job.professional!.id}',
    );
    if (review == null || !mounted) return;
    setState(() => _actionMessage = '¡Gracias por tu opinión!');
    await _refresh();
  }

  Future<void> _runWorkflow(JobModel job, JobPrimaryAction action) async {
    if (_processingAction != null || !await _confirmAction(action.type)) return;
    if (action.type == JobWorkflowActionType.confirm &&
        job.completionCode == null) {
      await _refresh();
      if (mounted) {
        setState(
          () => _actionMessage = 'No hay un código de finalización vigente. Actualizamos la chamba.',
        );
      }
      return;
    }
    setState(() {
      _processingAction = action.type;
      _actionMessage = null;
    });
    try {
      final repository = ref.read(jobRepositoryProvider);
      switch (action.type) {
        case JobWorkflowActionType.acceptJob:
          await repository.acceptJob(job.id);
        case JobWorkflowActionType.rejectJob:
          await repository.rejectJob(job.id);
        case JobWorkflowActionType.pay:
          if (mounted) context.push('/jobs/${job.id}/checkout');
          return;
        case JobWorkflowActionType.onTheWay:
          await repository.markOnTheWay(job.id);
        case JobWorkflowActionType.arrived:
          await repository.markArrived(job.id);
        case JobWorkflowActionType.start:
          await repository.startJob(job.id);
        case JobWorkflowActionType.finish:
          await repository.finishJob(job.id);
        case JobWorkflowActionType.confirm:
          await repository.confirmJob(job.id, job.completionCode!);
        case JobWorkflowActionType.dispute:
          return;
      }
      await _refresh();
      if (mounted) {
        setState(() => _actionMessage = 'Estado actualizado correctamente.');
      }
    } on AppException catch (error) {
      await _recoverWorkflow(error);
    } finally {
      if (mounted) setState(() => _processingAction = null);
    }
  }

  Future<bool> _confirmAction(JobWorkflowActionType type) async {
    final content = switch (type) {
      JobWorkflowActionType.acceptJob => (
        '¿Aceptar esta solicitud?',
        'El cliente podrá proceder con el pago del servicio.',
      ),
      JobWorkflowActionType.rejectJob => (
        '¿Rechazar esta solicitud?',
        'La solicitud quedará cancelada.',
      ),
      JobWorkflowActionType.arrived => (
        '¿Confirmas que ya llegaste al lugar?',
        'Registrar llegada',
      ),
      JobWorkflowActionType.finish => (
        '¿Terminaste el trabajo?',
        'Después esperaremos la confirmación del cliente.',
      ),
      _ => null,
    };
    if (content == null) return true;
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(content.$1),
            content: Text(content.$2),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Volver'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(
                  type == JobWorkflowActionType.finish
                      ? 'Sí, terminé'
                      : 'Confirmar',
                ),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _recoverWorkflow(AppException error) async {
    await _refresh();
    if (!mounted) return;
    setState(() {
      _actionMessage = switch (error.code) {
        'PAYMENT_REQUIRED' => 'El pago todavía no está confirmado.',
        'INVALID_JOB_TRANSITION' || 'JOB_ALREADY_COMPLETED' =>
          'El estado de esta chamba cambió. Actualizamos la información.',
        _ when error.statusCode == 409 =>
          'El estado de esta chamba cambió. Actualizamos la información.',
        _ when error.statusCode == null => 'No pudimos confirmar la acción. Consultamos el estado antes de permitir otro intento.',
        _ => error.message,
      };
    });
  }

  Future<void> _openMaps(JobModel job) async {
    final query = job.latitude != null && job.longitude != null
        ? '${job.latitude},${job.longitude}'
        : job.address;
    if (query == null || query.isEmpty) return;
    final native = Uri(
      scheme: 'geo',
      path: job.latitude != null ? query : '0,0',
      queryParameters: {'q': query},
    );
    final fallback = Uri.https('www.google.com', '/maps/search/', {
      'api': '1',
      'query': query,
    });
    final opened = await launchUrl(
      native,
      mode: LaunchMode.externalApplication,
    );
    if (!opened) {
      await launchUrl(fallback, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _accept(JobModel job, JobQuoteModel quote) async {
    if (_processingQuote != null) return;
    setState(() => _processingQuote = quote.id);
    try {
      await ref.read(quoteRepositoryProvider).acceptQuote(job.id, quote.id);
      await _refresh();
      if (mounted) context.push('/jobs/${job.id}/checkout');
    } on AppException catch (error) {
      await _recoverQuoteAction(error);
    } finally {
      if (mounted) setState(() => _processingQuote = null);
    }
  }

  Future<void> _reject(JobModel job, JobQuoteModel quote) async {
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('¿Quieres rechazar esta cotización?'),
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Text('Selecciona el motivo que enviaremos al servidor.'),
          ),
          for (final option in const {
            'price_high': 'El precio es demasiado alto',
            'changed_need': 'Cambió lo que necesito',
            'no_longer_needed': 'Ya no necesito el servicio',
          }.entries)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, option.key),
              child: Text(option.value),
            ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context),
            child: const Text('Volver'),
          ),
        ],
      ),
    );
    if (reason == null || _processingQuote != null) return;
    setState(() => _processingQuote = quote.id);
    try {
      await ref
          .read(quoteRepositoryProvider)
          .rejectQuote(job.id, quote.id, reason: reason);
      setState(() => _actionMessage = 'Cotización rechazada.');
      await _refresh();
    } on AppException catch (error) {
      await _recoverQuoteAction(error);
    } finally {
      if (mounted) setState(() => _processingQuote = null);
    }
  }

  Future<void> _recoverQuoteAction(AppException error) async {
    await _refresh();
    if (!mounted) return;
    setState(() {
      _actionMessage = switch (error.code) {
        'QUOTE_EXPIRED' => 'Esta cotización ya expiró.',
        'QUOTE_UNAVAILABLE' => 'Esta cotización ya fue procesada.',
        _ when error.statusCode == null =>
          'No pudimos confirmar la acción. Actualizamos el estado.',
        _ => error.message,
      };
    });
  }
}

class _StatusHeader extends StatelessWidget {
  const _StatusHeader({
    required this.job,
    required this.isClient,
    required this.isProfessional,
  });
  final JobModel job;
  final bool isClient;
  final bool isProfessional;

  @override
  Widget build(BuildContext context) {
    final (title, subtitle) = switch (job.status) {
      JobStatus.awaitingPayment => isProfessional
          ? ('Cliente aceptó', 'Esperando confirmación del pago.')
          : ('Confirmar contratación', 'Esperando pago para confirmar la chamba.'),
      JobStatus.paid => isProfessional
          ? ('Pago confirmado', null)
          : ('Pago en custodia', null),
      JobStatus.onTheWay => isProfessional
          ? ('Vas en camino', null)
          : ('Tu profesional va en camino', 'Actualizaremos el estado mientras ves esta pantalla.'),
      JobStatus.arrived => isProfessional
          ? ('Llegaste al servicio', null)
          : ('Tu profesional llegó', null),
      JobStatus.inProgress => isProfessional
          ? ('Trabajo en proceso', null)
          : ('Tu chamba está en proceso', null),
      JobStatus.awaitingConfirmation => ('Esperando confirmación', null),
      JobStatus.completed => ('Chamba completada', null),
      JobStatus.disputed => ('En revisión', null),
      _ => (job.status.label, null),
    };
    return Card(
      color: AppColors.amber.withValues(alpha: .08),
      child: ListTile(
        leading: const Icon(Icons.work_history_outlined),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
        subtitle: subtitle != null ? Text(subtitle) : null,
      ),
    );
  }
}

class _QuoteCard extends StatelessWidget {
  const _QuoteCard({
    required this.job,
    required this.quote,
    required this.processing,
    required this.onAccept,
    required this.onReject,
  });
  final JobModel job;
  final JobQuoteModel quote;
  final bool processing;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recibiste una cotización',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          if (job.professional != null) Text(job.professional!.name),
          Text(
            'Precio base: \$${quote.economicBreakdown?.baseAmount ?? quote.amount} ${quote.currency}',
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
          ),
          if (quote.economicBreakdown?.clientServiceFee != null) ...[
            Text(
              'Cargo de servicio Chambapp (${quote.economicBreakdown!.clientServiceFeePercent}%): +\$${quote.economicBreakdown!.clientServiceFee}',
            ),
            Text(
              'Total: \$${quote.economicBreakdown!.customerTotal} ${quote.currency}',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ],
          Text(quote.description),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: processing ? null : onReject,
                  child: const Text('Rechazar'),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: FilledButton(
                  onPressed: processing ? null : onAccept,
                  child: Text(processing ? 'Procesando…' : 'Aceptar'),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

class _ProfessionalPayment extends StatelessWidget {
  const _ProfessionalPayment({required this.payment});
  final PaymentModel payment;

  @override
  Widget build(BuildContext context) => Card(
    color: AppColors.success.withValues(alpha: .06),
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Desglose del pago',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          _Detail(
            label: 'Precio base',
            value:
                '\$${payment.baseAmount ?? payment.grossAmount} ${payment.currency}',
          ),
          _Detail(
            label: 'Comisión Chambapp',
            value:
                '${payment.professionalCommissionPercent ?? payment.platformFeePercent}% · \$${payment.professionalCommission ?? payment.platformFee}',
          ),
          _Detail(
            label: 'Monto estimado',
            value:
                '\$${payment.professionalAmountBeforeExternalCosts ?? payment.professionalAmount} ${payment.currency}',
          ),
          const Text(
            'Antes de impuestos, retenciones y costos externos aplicables.',
          ),
        ],
      ),
    ),
  );
}

class _OperationalData extends StatelessWidget {
  const _OperationalData({required this.job, required this.onOpenMaps});
  final JobModel job;
  final VoidCallback onOpenMaps;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Datos operativos habilitados por el servidor',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          if (job.address != null)
            Text([job.address, job.postalCode].whereType<String>().join(', ')),
          const SizedBox(height: AppSpacing.sm),
          OutlinedButton.icon(
            onPressed: onOpenMaps,
            icon: const Icon(Icons.map_outlined),
            label: const Text('Abrir en mapas'),
          ),
        ],
      ),
    ),
  );
}

class _ProfessionalCard extends StatelessWidget {
  const _ProfessionalCard({required this.job});
  final JobModel job;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          RemoteImage(
            url: job.professional!.avatarUrl,
            width: 56,
            height: 56,
            borderRadius: BorderRadius.circular(28),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  job.professional!.name,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                Text('★ ${job.professional!.rating.toStringAsFixed(1)}'),
                if (job.professional!.verified)
                  const Text('Profesional verificado'),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _StateCard extends StatelessWidget {
  const _StateCard({required this.title, required this.body});
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(title: Text(title), subtitle: Text(body)),
  );
}

class _SuccessNotice extends StatelessWidget {
  const _SuccessNotice();

  @override
  Widget build(BuildContext context) => const Card(
    child: Padding(
      padding: EdgeInsets.all(AppSpacing.md),
      child: Text('Tu chamba fue programada correctamente.'),
    ),
  );
}

class _Detail extends StatelessWidget {
  const _Detail({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 115,
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
        Expanded(child: Text(value)),
      ],
    ),
  );
}

class _JobTimeline extends StatelessWidget {
  const _JobTimeline({required this.job});
  final JobModel job;

  @override
  Widget build(BuildContext context) {
    final isDirect = job.service != null;
    final progress = isDirect
        ? switch (job.status) {
            JobStatus.pending || JobStatus.awaitingPayment => 0,
            JobStatus.paid => 1,
            JobStatus.onTheWay => 2,
            JobStatus.arrived => 3,
            JobStatus.inProgress => 4,
            JobStatus.awaitingConfirmation || JobStatus.disputed => 5,
            JobStatus.completed => 6,
            _ => 0,
          }
        : switch (job.status) {
            JobStatus.pending || JobStatus.searching => 0,
            JobStatus.matched || JobStatus.accepted || JobStatus.awaitingQuote => 1,
            JobStatus.awaitingPayment => 2,
            JobStatus.paid => 3,
            JobStatus.onTheWay => 4,
            JobStatus.arrived => 5,
            JobStatus.inProgress => 6,
            JobStatus.awaitingConfirmation || JobStatus.disputed => 7,
            JobStatus.completed => 8,
            _ => 0,
          };

    final steps = isDirect
        ? <(String, DateTime?)>[
            ('Contratación creada', job.createdAt),
            ('Pago confirmado', job.payment?.paidAt),
            ('En camino', null),
            ('Llegó', null),
            ('Trabajo iniciado', null),
            (
              job.status == JobStatus.disputed
                  ? 'Reporte en revisión'
                  : 'Profesional terminó',
              null,
            ),
            (
              'Cliente confirmó',
              job.status == JobStatus.completed ? job.updatedAt : null,
            ),
          ]
        : <(String, DateTime?)>[
            ('Solicitud creada', job.createdAt),
            ('Profesional encontrado', null),
            ('Cotización', null),
            ('Pago', job.payment?.paidAt),
            ('En camino', null),
            ('Llegó', null),
            ('Trabajo iniciado', null),
            (
              job.status == JobStatus.disputed
                  ? 'Reporte en revisión'
                  : 'Profesional terminó',
              null,
            ),
            (
              'Cliente confirmó',
              job.status == JobStatus.completed ? job.updatedAt : null,
            ),
          ];
    return Column(
      children: List.generate(steps.length, (index) {
        final done = index <= progress;
        return Semantics(
          label: '${steps[index].$1}: ${done ? 'completado' : 'pendiente'}',
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(
              done ? Icons.check_circle : Icons.radio_button_unchecked,
              color: done ? AppColors.success : AppColors.muted,
            ),
            title: Text(steps[index].$1),
            subtitle: steps[index].$2 == null
                ? null
                : Text(_localDate(steps[index].$2!)),
          ),
        );
      }),
    );
  }
}

String _localDate(DateTime value, [String? slot]) {
  final local = value.toLocal();
  final date =
      '${local.day.toString().padLeft(2, '0')}/'
      '${local.month.toString().padLeft(2, '0')}/${local.year} '
      '${local.hour.toString().padLeft(2, '0')}:'
      '${local.minute.toString().padLeft(2, '0')}';
  return slot == null || slot.isEmpty ? date : '$date · $slot';
}
