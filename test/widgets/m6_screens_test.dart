import 'dart:async';

import 'package:chambapp_mobile/app/providers.dart';
import 'package:chambapp_mobile/core/errors/app_exception.dart';
import 'package:chambapp_mobile/core/theme/app_theme.dart';
import 'package:chambapp_mobile/features/jobs/domain/commerce_repositories.dart';
import 'package:chambapp_mobile/features/jobs/domain/job_models.dart';
import 'package:chambapp_mobile/features/jobs/presentation/dispute_screen.dart';
import 'package:chambapp_mobile/features/jobs/presentation/job_detail_screen.dart';
import 'package:chambapp_mobile/features/jobs/presentation/job_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fakes.dart';
import '../helpers/m2_fakes.dart';
import '../helpers/m3_fakes.dart';

const _payment = PaymentModel(
  id: 9,
  jobId: 12,
  status: PaymentStatus.approved,
  grossAmount: '900.00',
  platformFeePercent: '10.00',
  platformFee: '90.00',
  professionalAmount: '810.00',
  currency: 'MXN',
);

JobModel _job(JobStatus status, {String? completionCode}) => JobModel(
  id: 12,
  title: 'Reparación de fuga',
  description: 'Reparar una fuga debajo del fregadero.',
  status: status,
  statusLabel: status.label,
  category: testCategory,
  professional: testProfessional,
  agreedPrice: '900.00',
  currency: 'MXN',
  payment: _payment,
  address: 'Calle Reforma 123',
  postalCode: '44100',
  latitude: '20.67',
  longitude: '-103.34',
  completionCode: completionCode,
);

final class _Quotes implements QuoteRepository {
  @override
  Future<JobQuoteModel> acceptQuote(int jobId, int quoteId) =>
      throw UnimplementedError();
  @override
  Future<JobQuoteModel> createQuote(
    int jobId, {
    required String amount,
    required String description,
  }) => throw UnimplementedError();
  @override
  Future<List<JobQuoteModel>> getQuotes(int jobId, {int page = 1}) async => [];
  @override
  Future<JobQuoteModel> rejectQuote(
    int jobId,
    int quoteId, {
    required String reason,
    String? reasonDetail,
  }) => throw UnimplementedError();
}

Future<ProviderContainer> _container(
  FakeJobRepository jobs, {
  bool professional = false,
}) async {
  final container = ProviderContainer(
    overrides: [
      authRepositoryProvider.overrideWithValue(
        professional ? FakeProfessionalAuthRepository() : FakeAuthRepository(),
      ),
      jobRepositoryProvider.overrideWithValue(jobs),
      quoteRepositoryProvider.overrideWithValue(_Quotes()),
    ],
  );
  await container
      .read(authControllerProvider.notifier)
      .login(email: 'test@example.test', password: 'secret');
  return container;
}

Widget _app(ProviderContainer container, Widget child) =>
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(theme: AppTheme.light, home: child),
    );

Future<void> _scrollTo(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(
    finder,
    240,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pump();
}

void main() {
  testWidgets('profesional avanza paid y doble tap produce una sola petición', (
    tester,
  ) async {
    final jobs = FakeJobRepository()
      ..job = _job(JobStatus.paid)
      ..workflowCompleter = Completer<JobModel>();
    final container = await _container(jobs, professional: true);
    addTearDown(container.dispose);
    await tester.pumpWidget(_app(container, const JobDetailScreen(jobId: 12)));
    await tester.pump();

    expect(find.text('Pago confirmado'), findsOneWidget);
    expect(find.text('Ir al servicio'), findsOneWidget);
    await tester.tap(find.text('Ir al servicio'));
    await tester.tap(find.text('Ir al servicio'));
    await tester.pump();
    expect(jobs.onTheWayCalls, 1);
    expect(find.text('Actualizando estado…'), findsOneWidget);

    jobs.job = _job(JobStatus.onTheWay);
    jobs.workflowCompleter!.complete(jobs.job);
    await tester.pumpAndSettle();
    expect(find.text('Vas en camino'), findsOneWidget);
    expect(find.text('Ya llegué'), findsOneWidget);
  });

  testWidgets('cliente confirma con código API y no ve acciones profesional', (
    tester,
  ) async {
    final jobs = FakeJobRepository()
      ..job = _job(JobStatus.awaitingConfirmation, completionCode: '123456')
      ..workflowCompleter = Completer<JobModel>();
    final container = await _container(jobs);
    addTearDown(container.dispose);
    await tester.pumpWidget(_app(container, const JobDetailScreen(jobId: 12)));
    await tester.pump();

    expect(find.text('Confirmar trabajo'), findsOneWidget);
    await _scrollTo(tester, find.text('Reportar un problema'));
    expect(find.text('Reportar un problema'), findsOneWidget);
    expect(find.text('Marcar como terminado'), findsNothing);
    await tester.tap(find.text('Confirmar trabajo'));
    await tester.tap(find.text('Confirmar trabajo'));
    await tester.pump();
    expect(jobs.confirmCalls, 1);

    jobs.job = _job(JobStatus.completed);
    jobs.workflowCompleter!.complete(jobs.job);
    await tester.pumpAndSettle();
    expect(find.text('Chamba completada'), findsWidgets);
    expect(find.text('Confirmar trabajo'), findsNothing);
  });

  testWidgets(
    'llegada, inicio y fin bloquean doble tap y respetan confirmaciones',
    (tester) async {
      final cases = [
        (
          status: JobStatus.onTheWay,
          label: 'Ya llegué',
          confirm: 'Confirmar',
          calls: (FakeJobRepository jobs) => jobs.arrivedCalls,
        ),
        (
          status: JobStatus.arrived,
          label: 'Iniciar trabajo',
          confirm: null,
          calls: (FakeJobRepository jobs) => jobs.startCalls,
        ),
        (
          status: JobStatus.inProgress,
          label: 'Marcar como terminado',
          confirm: 'Sí, terminé',
          calls: (FakeJobRepository jobs) => jobs.finishCalls,
        ),
      ];
      for (final item in cases) {
        final jobs = FakeJobRepository()
          ..job = _job(item.status)
          ..workflowCompleter = Completer<JobModel>();
        final container = await _container(jobs, professional: true);
        await tester.pumpWidget(
          _app(container, const JobDetailScreen(jobId: 12)),
        );
        await tester.pump();
        await tester.tap(find.text(item.label));
        await tester.pump();
        if (item.confirm != null) {
          await tester.tap(find.text(item.confirm!));
          await tester.pump();
        }
        expect(item.calls(jobs), 1, reason: item.label);
        await tester.tap(find.byType(FilledButton).last, warnIfMissed: false);
        expect(item.calls(jobs), 1, reason: 'doble tap ${item.label}');
        jobs.workflowCompleter!.complete(jobs.job);
        await tester.pumpAndSettle();
        await tester.pumpWidget(const SizedBox());
        container.dispose();
      }
    },
  );

  testWidgets('timeout ambiguo refresca sin declarar una transición falsa', (
    tester,
  ) async {
    final jobs = FakeJobRepository()
      ..job = _job(JobStatus.paid)
      ..workflowError = const AppException(message: 'Sin red');
    final container = await _container(jobs, professional: true);
    addTearDown(container.dispose);
    await tester.pumpWidget(_app(container, const JobDetailScreen(jobId: 12)));
    await tester.pump();
    final initialReads = jobs.getJobCalls;

    await tester.tap(find.text('Ir al servicio'));
    await tester.pumpAndSettle();
    await _scrollTo(tester, find.textContaining('Consultamos el estado'));
    expect(jobs.getJobCalls, greaterThan(initialReads));
    expect(find.textContaining('Consultamos el estado'), findsOneWidget);
    expect(find.text('Ir al servicio'), findsOneWidget);
  });

  testWidgets('409 y PAYMENT_REQUIRED muestran mensajes de dominio', (
    tester,
  ) async {
    for (final error in const [
      AppException(
        message: 'Conflicto',
        statusCode: 409,
        code: 'INVALID_JOB_TRANSITION',
      ),
      AppException(message: 'Pago', statusCode: 409, code: 'PAYMENT_REQUIRED'),
    ]) {
      final jobs = FakeJobRepository()
        ..job = _job(JobStatus.paid)
        ..workflowError = error;
      final container = await _container(jobs, professional: true);
      await tester.pumpWidget(
        _app(container, const JobDetailScreen(jobId: 12)),
      );
      await tester.pump();
      await tester.tap(find.text('Ir al servicio'));
      await tester.pumpAndSettle();
      await _scrollTo(
        tester,
        find.textContaining(
          error.code == 'PAYMENT_REQUIRED'
              ? 'pago todavía no está confirmado'
              : 'estado de esta chamba cambió',
        ),
      );
      expect(
        find.textContaining(
          error.code == 'PAYMENT_REQUIRED'
              ? 'pago todavía no está confirmado'
              : 'estado de esta chamba cambió',
        ),
        findsOneWidget,
      );
      await tester.pumpWidget(const SizedBox());
      container.dispose();
    }
  });

  testWidgets('reinicio recupera in_progress y completed desde backend', (
    tester,
  ) async {
    for (final entry in [
      (_job(JobStatus.inProgress), 'Marcar como terminado'),
      (_job(JobStatus.completed), 'Gracias por usar Chambapp.'),
    ]) {
      final jobs = FakeJobRepository()..job = entry.$1;
      final container = await _container(
        jobs,
        professional: entry.$1.status == JobStatus.inProgress,
      );
      await tester.pumpWidget(
        _app(container, const JobDetailScreen(jobId: 12)),
      );
      await tester.pump();
      if (entry.$1.status == JobStatus.completed) {
        await _scrollTo(tester, find.text(entry.$2));
      }
      expect(find.text(entry.$2), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      container.dispose();
    }
  });

  testWidgets('polling operativo pausa en background y reanuda al volver', (
    tester,
  ) async {
    final jobs = FakeJobRepository()..job = _job(JobStatus.onTheWay);
    final container = await _container(jobs);
    addTearDown(container.dispose);
    await tester.pumpWidget(_app(container, const JobDetailScreen(jobId: 12)));
    await tester.pump();
    final initial = jobs.getJobCalls;
    await tester.pump(const Duration(seconds: 8));
    await tester.pump();
    expect(jobs.getJobCalls, greaterThan(initial));

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    final paused = jobs.getJobCalls;
    await tester.pump(const Duration(seconds: 8));
    expect(jobs.getJobCalls, paused);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(jobs.getJobCalls, greaterThan(paused));
  });

  testWidgets('snapshot de Payment no se recalcula durante M6', (tester) async {
    final jobs = FakeJobRepository()..job = _job(JobStatus.inProgress);
    final container = await _container(jobs, professional: true);
    addTearDown(container.dispose);
    await tester.pumpWidget(_app(container, const JobDetailScreen(jobId: 12)));
    await tester.pump();
    await _scrollTo(tester, find.textContaining('10.00%'));
    expect(find.textContaining('10.00%'), findsOneWidget);
    expect(find.textContaining(r'$90.00'), findsOneWidget);
    expect(find.textContaining(r'$810.00'), findsOneWidget);
  });

  testWidgets(
    'formulario de disputa usa motivos estructurados y no promete refund',
    (tester) async {
      final jobs = FakeJobRepository()
        ..workflowResult = _job(JobStatus.disputed);
      final container = await _container(jobs);
      addTearDown(container.dispose);
      await tester.pumpWidget(_app(container, const DisputeScreen(jobId: 12)));
      await tester.pump();
      expect(
        find.textContaining('no genera un reembolso automático'),
        findsOneWidget,
      );
      await tester.tap(find.byType(DropdownButtonFormField<DisputeReason>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Trabajo incompleto').last);
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Descripción (opcional)'),
        'Faltó una parte del trabajo.',
      );
      await tester.tap(find.text('Enviar reporte'));
      await tester.pumpAndSettle();
      expect(jobs.disputeCalls, 1);
    },
  );

  testWidgets('detalle operativo responde en anchos móviles', (tester) async {
    for (final width in [320.0, 360.0, 390.0, 412.0, 480.0]) {
      tester.view.physicalSize = Size(width, 800);
      tester.view.devicePixelRatio = 1;
      final jobs = FakeJobRepository()..job = _job(JobStatus.paid);
      final container = await _container(jobs, professional: true);
      await tester.pumpWidget(
        _app(container, const JobDetailScreen(jobId: 12)),
      );
      await tester.pump();
      expect(tester.takeException(), isNull, reason: 'ancho $width');
      await tester.pumpWidget(const SizedBox());
      container.dispose();
    }
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  });
}
