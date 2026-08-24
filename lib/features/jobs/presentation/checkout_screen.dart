import 'dart:async';

import 'package:chambapp_mobile/core/errors/app_exception.dart';
import 'package:chambapp_mobile/core/theme/app_tokens.dart';
import 'package:chambapp_mobile/features/jobs/domain/job_models.dart';
import 'package:chambapp_mobile/features/jobs/presentation/job_providers.dart';
import 'package:chambapp_mobile/shared/widgets/error_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

typedef ExternalUrlLauncher = Future<bool> Function(Uri uri);
final externalUrlLauncherProvider = Provider<ExternalUrlLauncher>(
  (_) =>
      (uri) => launchUrl(uri, mode: LaunchMode.externalApplication),
);

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({required this.jobId, super.key});
  final int jobId;
  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen>
    with WidgetsBindingObserver {
  Timer? _pollTimer;
  PaymentModel? _payment;
  bool _preparing = false;
  bool _checking = false;
  String? _message;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _verify();
    if (state != AppLifecycleState.resumed) _pollTimer?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    final detail = ref.watch(jobDetailProvider(widget.jobId));
    final payment = _payment ?? detail.value?.payment;
    if (_payment == null && payment != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _payment == null) {
          setState(() => _payment = payment);
          _schedulePoll();
        }
      });
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Pago de la chamba')),
      body: detail.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => ErrorState(
          title: 'No pudimos cargar el pago',
          message: error,
          onRetry: () => ref.invalidate(jobDetailProvider(widget.jobId)),
        ),
        data: (job) => ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            Text(
              job.status == JobStatus.paid
                  ? 'Pago aprobado'
                  : 'Cotización aceptada',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: AppSpacing.md),
            _Summary(job: job, payment: payment),
            const SizedBox(height: AppSpacing.lg),
            _PaymentState(payment: payment, job: job),
            if (_message != null) ...[
              const SizedBox(height: AppSpacing.md),
              Text(_message!, textAlign: TextAlign.center),
            ],
            const SizedBox(height: AppSpacing.xl),
            if (job.status != JobStatus.paid &&
                payment?.status != PaymentStatus.approved)
              FilledButton.icon(
                onPressed: _preparing ? null : () => _confirmAndCheckout(job),
                icon: _preparing
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.open_in_new),
                label: Text(
                  _preparing ? 'Preparando pago…' : 'Pagar en Chambapp',
                ),
              ),
            if (payment != null && payment.status != PaymentStatus.approved)
              TextButton(
                onPressed: _checking ? null : _verify,
                child: Text(_checking ? 'Verificando…' : 'Verificar pago'),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmAndCheckout(JobModel job) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Abrir Mercado Pago'),
        content: Text(
          'Total: \$${_payment?.customerTotal ?? job.economicBreakdown?.customerTotal ?? job.agreedPrice ?? '--'} ${_payment?.currency ?? job.currency ?? 'MXN'}\n\nEl pago se confirmará únicamente cuando Laravel reciba el resultado de Mercado Pago.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Volver'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Continuar'),
          ),
        ],
      ),
    );
    if (confirmed != true || _preparing) return;
    setState(() {
      _preparing = true;
      _message = null;
    });
    try {
      final result = await ref
          .read(paymentRepositoryProvider)
          .createCheckout(widget.jobId);
      if (!mounted) return;
      setState(() => _payment = result.payment);
      final uri = Uri.tryParse(result.checkoutUrl);
      final opened =
          uri != null && await ref.read(externalUrlLauncherProvider)(uri);
      if (mounted && !opened) {
        setState(
          () => _message = 'No pudimos abrir Mercado Pago. Intenta nuevamente.',
        );
      }
      _schedulePoll();
    } on AppException catch (error) {
      if (error.statusCode == null) {
        await _recoverCheckoutTimeout();
      } else if (mounted) {
        setState(
          () => _message = 'No pudimos iniciar el pago. Intenta nuevamente.',
        );
      }
    } finally {
      if (mounted) setState(() => _preparing = false);
    }
  }

  Future<void> _recoverCheckoutTimeout() async {
    try {
      final job = await ref.read(jobRepositoryProvider).getJob(widget.jobId);
      if (!mounted) return;
      setState(() {
        _payment = job.payment;
        _message = job.payment == null
            ? 'No pudimos confirmar si se creó el pago. Verifica antes de intentar nuevamente.'
            : 'Encontramos el intento de pago. Verificaremos su estado sin crear otro automáticamente.';
      });
      if (job.payment != null) _schedulePoll();
    } catch (_) {
      if (mounted) {
        setState(() => _message = 'No pudimos verificar el pago todavía.');
      }
    }
  }

  Future<void> _verify() async {
    final payment = _payment;
    if (payment == null || _checking) {
      ref.invalidate(jobDetailProvider(widget.jobId));
      return;
    }
    setState(() => _checking = true);
    try {
      final fresh = await ref
          .read(paymentRepositoryProvider)
          .getPayment(payment.id);
      if (!mounted) return;
      setState(() {
        _payment = fresh;
        _message = null;
      });
      ref.invalidate(jobDetailProvider(widget.jobId));
      if (!fresh.status.terminal) _schedulePoll();
    } catch (_) {
      if (mounted) {
        setState(() => _message = 'No pudimos verificar el pago todavía.');
        _schedulePoll(seconds: 15);
      }
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  void _schedulePoll({int seconds = 7}) {
    _pollTimer?.cancel();
    if (_payment?.status.terminal == true) return;
    _pollTimer = Timer(Duration(seconds: seconds), _verify);
  }
}

class _Summary extends StatelessWidget {
  const _Summary({required this.job, required this.payment});
  final JobModel job;
  final PaymentModel? payment;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            job.category?.name ?? job.title,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          if (job.professional != null)
            Text('Profesional: ${job.professional!.name}'),
          const Divider(),
          Text(
            'Precio base: \$${payment?.baseAmount ?? job.economicBreakdown?.baseAmount ?? job.agreedPrice ?? '--'} ${payment?.currency ?? job.currency ?? 'MXN'}',
          ),
          if (payment?.clientServiceFee != null ||
              job.economicBreakdown?.clientServiceFee != null)
            Text(
              'Cargo de servicio Chambapp (${payment?.clientServiceFeePercent ?? job.economicBreakdown?.clientServiceFeePercent}%): +\$${payment?.clientServiceFee ?? job.economicBreakdown?.clientServiceFee}',
            ),
          Text(
            'Total: \$${payment?.customerTotal ?? job.economicBreakdown?.customerTotal ?? payment?.grossAmount ?? job.agreedPrice ?? '--'} ${payment?.currency ?? job.currency ?? 'MXN'}',
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20),
          ),
          const Text(
            'El cargo Chambapp es un cargo de servicio, no un impuesto.',
          ),
          const Text('Pago procesado de forma segura por Mercado Pago.'),
        ],
      ),
    ),
  );
}

class _PaymentState extends StatelessWidget {
  const _PaymentState({required this.payment, required this.job});
  final PaymentModel? payment;
  final JobModel job;
  @override
  Widget build(BuildContext context) {
    final status = payment?.status;
    final (icon, title, body, color) = switch (status) {
      PaymentStatus.approved => (
        Icons.check_circle,
        'Pago aprobado',
        'Tu chamba ya está contratada.',
        AppColors.success,
      ),
      PaymentStatus.rejected => (
        Icons.error_outline,
        'No pudimos procesar el pago',
        'Puedes iniciar un nuevo intento cuando estés listo.',
        AppColors.danger,
      ),
      PaymentStatus.cancelled => (
        Icons.cancel_outlined,
        'Pago cancelado',
        'La chamba no se marcó como pagada.',
        AppColors.danger,
      ),
      PaymentStatus.refunded || PaymentStatus.partiallyRefunded => (
        Icons.undo,
        'Pago reembolsado',
        'Consulta el estado actualizado con Chambapp.',
        AppColors.amberDark,
      ),
      PaymentStatus.pending || PaymentStatus.processing => (
        Icons.hourglass_top,
        'Tu pago está siendo procesado',
        'Volver del navegador no significa que haya sido aprobado.',
        AppColors.amberDark,
      ),
      _ when job.status == JobStatus.paid => (
        Icons.check_circle,
        'Pago aprobado',
        'Tu chamba ya está contratada.',
        AppColors.success,
      ),
      _ => (
        Icons.lock_outline,
        'Pago pendiente',
        'Mercado Pago y Laravel confirmarán el resultado.',
        AppColors.navy,
      ),
    };
    return Card(
      color: color.withValues(alpha: .08),
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(title),
        subtitle: Text(body),
      ),
    );
  }
}
