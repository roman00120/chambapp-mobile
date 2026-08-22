import 'dart:async';

import 'package:chambapp_mobile/app/providers.dart';
import 'package:chambapp_mobile/core/errors/app_exception.dart';
import 'package:chambapp_mobile/core/theme/app_theme.dart';
import 'package:chambapp_mobile/features/catalog/presentation/catalog_providers.dart';
import 'package:chambapp_mobile/features/home/presentation/client_home_screen.dart';
import 'package:chambapp_mobile/features/jobs/domain/job_models.dart';
import 'package:chambapp_mobile/features/jobs/presentation/immediate_job_screen.dart';
import 'package:chambapp_mobile/features/jobs/presentation/job_providers.dart';
import 'package:chambapp_mobile/features/jobs/presentation/scheduled_job_screen.dart';
import 'package:chambapp_mobile/features/jobs/presentation/searching_job_screen.dart';
import 'package:chambapp_mobile/features/jobs/presentation/widgets/job_card.dart';
import 'package:chambapp_mobile/features/notifications/presentation/notification_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fakes.dart';
import '../helpers/m2_fakes.dart';

Widget _material(Widget child) =>
    MaterialApp(theme: AppTheme.light, home: child);

ProviderContainer _container({FakeJobRepository? jobs}) => ProviderContainer(
  overrides: [
    authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
    categoryRepositoryProvider.overrideWithValue(FakeCategoryRepository()),
    serviceRepositoryProvider.overrideWithValue(FakeServiceRepository()),
    professionalRepositoryProvider.overrideWithValue(
      FakeProfessionalRepository(),
    ),
    notificationRepositoryProvider.overrideWithValue(
      FakeNotificationRepository(),
    ),
    if (jobs != null) jobRepositoryProvider.overrideWithValue(jobs),
  ],
);

void main() {
  testWidgets('home cliente muestra búsqueda, categorías y CTAs', (
    tester,
  ) async {
    final container = _container();
    addTearDown(container.dispose);
    await container
        .read(authControllerProvider.notifier)
        .login(email: 'ana@example.test', password: 'secret');
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: _material(const ClientHomeScreen()),
      ),
    );
    await tester.pump();
    expect(find.byKey(const Key('client_home')), findsOneWidget);
    expect(find.text('¿Qué necesitas hoy?'), findsOneWidget);
    expect(find.byKey(const Key('home_immediate')), findsOneWidget);
    expect(find.byKey(const Key('home_scheduled')), findsOneWidget);
    expect(find.text('Plomería'), findsOneWidget);
  });

  testWidgets(
    'formularios immediate y scheduled renderizan categorías reales',
    (tester) async {
      final container = _container();
      addTearDown(container.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: _material(const ImmediateJobScreen()),
        ),
      );
      await tester.pump();
      expect(find.text('¿Qué necesitas?'), findsOneWidget);
      expect(find.byKey(const Key('category_1')), findsOneWidget);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: _material(const ScheduledJobScreen()),
        ),
      );
      await tester.pump();
      expect(find.text('Programar chamba'), findsOneWidget);
      expect(find.byKey(const Key('category_1')), findsOneWidget);
    },
  );

  testWidgets('doble tap al crear job immediate dispara una sola petición', (
    tester,
  ) async {
    final jobs = FakeJobRepository()..immediateCompleter = Completer();
    final container = _container(jobs: jobs);
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: _material(const ImmediateJobScreen()),
      ),
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('category_1')));
    await tester.tap(find.byKey(const Key('wizard_next')));
    await tester.pump();
    await tester.enterText(
      find.byKey(const Key('immediate_description')),
      'Tengo una fuga debajo del fregadero.',
    );
    await tester.tap(find.byKey(const Key('wizard_next')));
    await tester.pump();
    await tester.enterText(
      find.byKey(const Key('location_address')),
      'Calle Uno 10',
    );
    await tester.enterText(
      find.byKey(const Key('location_city')),
      'Guadalajara',
    );
    await tester.enterText(find.byKey(const Key('location_state')), 'Jalisco');
    await tester.tap(find.byKey(const Key('wizard_next')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('wizard_next')));
    await tester.tap(find.byKey(const Key('wizard_next')));
    expect(jobs.immediateCalls, 1);
    jobs.immediateCompleter!.completeError(
      const AppException(message: 'Error controlado'),
    );
    await tester.pump();
  });

  testWidgets('polling cambia searching a matched', (tester) async {
    final jobs = FakeJobRepository(
      statuses: const [
        JobStatusModel(
          status: JobStatus.searching,
          label: 'Buscando profesional',
        ),
        JobStatusModel(
          status: JobStatus.matched,
          label: 'Profesional encontrado',
          professional: testProfessional,
        ),
      ],
    );
    final container = _container(jobs: jobs);
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: _material(
          const SearchingJobScreen(jobId: 12, initialJob: testJob),
        ),
      ),
    );
    await tester.pump();
    expect(find.byKey(const Key('job_searching')), findsOneWidget);
    await tester.pump(const Duration(seconds: 5));
    await tester.pump();
    expect(find.byKey(const Key('job_matched')), findsOneWidget);
  });

  testWidgets('estado expired muestra las tres alternativas', (tester) async {
    final jobs = FakeJobRepository(
      statuses: const [
        JobStatusModel(status: JobStatus.expired, label: 'Expirado'),
      ],
    );
    final container = _container(jobs: jobs);
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: _material(
          const SearchingJobScreen(jobId: 12, initialJob: testJob),
        ),
      ),
    );
    await tester.pump();
    expect(find.byKey(const Key('job_expired')), findsOneWidget);
    expect(find.text('Buscar nuevamente'), findsOneWidget);
    expect(find.text('Programar para después'), findsOneWidget);
    expect(find.text('Volver al inicio'), findsOneWidget);
  });

  testWidgets('job card muestra categoría y estado real', (tester) async {
    await tester.pumpWidget(_material(JobCard(job: testJob, onTap: () {})));
    expect(find.text('Plomería'), findsOneWidget);
    expect(find.text('Buscando profesional'), findsOneWidget);
  });

  for (final size in const [
    Size(320, 568),
    Size(360, 800),
    Size(390, 844),
    Size(412, 915),
    Size(800, 1024),
  ]) {
    testWidgets(
      'home responde en ${size.width.toInt()}x${size.height.toInt()}',
      (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final container = _container();
        addTearDown(container.dispose);
        await container
            .read(authControllerProvider.notifier)
            .login(email: 'ana@example.test', password: 'secret');
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: _material(const ClientHomeScreen()),
          ),
        );
        await tester.pump();
        expect(tester.takeException(), isNull);
      },
    );
  }
}
