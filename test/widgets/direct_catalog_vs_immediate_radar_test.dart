import 'package:chambapp_mobile/app/providers.dart';
import 'package:chambapp_mobile/core/theme/app_theme.dart';
import 'package:chambapp_mobile/features/catalog/presentation/catalog_providers.dart';
import 'package:chambapp_mobile/features/catalog/presentation/service_request_screen.dart';
import 'package:chambapp_mobile/features/jobs/domain/job_models.dart';
import 'package:chambapp_mobile/features/jobs/presentation/immediate_job_screen.dart';
import 'package:chambapp_mobile/features/jobs/presentation/job_providers.dart';
import 'package:chambapp_mobile/features/notifications/presentation/notification_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../helpers/fakes.dart';
import '../helpers/m2_fakes.dart';

void main() {
  testWidgets(
    'Direct catalog hiring navigates directly to checkout without showing radar',
    (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      String? navigatedLocation;

      final router = GoRouter(
        initialLocation: '/catalog/service/1/request',
        routes: [
          GoRoute(
            path: '/catalog/service/:id/request',
            builder: (context, state) => ServiceRequestScreen(
              serviceId: testService.id,
              service: testService,
            ),
          ),
          GoRoute(
            path: '/jobs/:id/checkout',
            builder: (context, state) {
              navigatedLocation = state.uri.toString();
              return Scaffold(
                body: Text('CHECKOUT_SCREEN_${state.pathParameters['id']}'),
              );
            },
          ),
          GoRoute(
            path: '/jobs/:id/searching',
            builder: (context, state) {
              navigatedLocation = state.uri.toString();
              return Scaffold(
                body: Text('RADAR_SCREEN_${state.pathParameters['id']}'),
              );
            },
          ),
        ],
      );

      const targetJob = JobModel(
        id: 77,
        title: 'Reparación de fugas',
        description: 'Instalación directa de servicio de plomería.',
        status: JobStatus.awaitingPayment,
        statusLabel: 'Pendiente de pago',
        category: testCategory,
      );

      final fakeJobs = FakeJobRepository()..scheduledJobResult = targetJob;
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
          categoryRepositoryProvider.overrideWithValue(FakeCategoryRepository()),
          serviceRepositoryProvider.overrideWithValue(FakeServiceRepository()),
          professionalRepositoryProvider.overrideWithValue(FakeProfessionalRepository()),
          notificationRepositoryProvider.overrideWithValue(FakeNotificationRepository()),
          jobRepositoryProvider.overrideWithValue(fakeJobs),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            theme: AppTheme.light,
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Completamos los campos del formulario de contratación directa
      await tester.enterText(
        find.byKey(const Key('request_address')),
        'Av. Juarez 500',
      );
      await tester.enterText(
        find.byKey(const Key('request_city')),
        'Guadalajara',
      );
      await tester.enterText(
        find.byKey(const Key('request_state')),
        'Jalisco',
      );
      await tester.enterText(
        find.byKey(const Key('request_postal')),
        '44100',
      );
      await tester.enterText(
        find.byKey(const Key('request_description')),
        'Instalación directa de servicio de plomería.',
      );

      // Verificamos que la pantalla de contratación directa NO muestra wizard ni pasos redundantes
      expect(find.textContaining('Paso '), findsNothing);
      expect(find.text('¿Qué necesitas?'), findsNothing);

      // Enviamos la solicitud directa
      await tester.tap(find.byKey(const Key('confirm_service_request')));
      await tester.pumpAndSettle();

      // Verificamos que navegó directamente a Checkout y NO a Radar
      expect(fakeJobs.createScheduledCalls, 1);
      expect(navigatedLocation, '/jobs/77/checkout');
      expect(find.text('CHECKOUT_SCREEN_77'), findsOneWidget);
      expect(find.textContaining('RADAR_SCREEN'), findsNothing);
    },
  );

  testWidgets(
    'Ahora flow displays available services for selected category and allows direct selection without radar',
    (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      String? navigatedLocation;

      final router = GoRouter(
        initialLocation: '/request/immediate',
        routes: [
          GoRoute(
            path: '/request/immediate',
            builder: (context, state) => const ImmediateJobScreen(),
          ),
          GoRoute(
            path: '/services/:id',
            builder: (context, state) {
              navigatedLocation = state.uri.toString();
              return Scaffold(
                body: Text('SERVICE_DETAIL_SCREEN_${state.pathParameters['id']}'),
              );
            },
          ),
        ],
      );

      final fakeServices = FakeServiceRepository()..services = [testService];
      final fakeJobs = FakeJobRepository();
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
          categoryRepositoryProvider.overrideWithValue(FakeCategoryRepository()),
          serviceRepositoryProvider.overrideWithValue(fakeServices),
          professionalRepositoryProvider.overrideWithValue(FakeProfessionalRepository()),
          notificationRepositoryProvider.overrideWithValue(FakeNotificationRepository()),
          jobRepositoryProvider.overrideWithValue(fakeJobs),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            theme: AppTheme.light,
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verificamos que la pantalla de Chamba ahora es directa y NO contiene wizard ni radar
      expect(find.text('Chamba ahora ⚡'), findsOneWidget);
      expect(find.textContaining('Paso '), findsNothing);

      // Seleccionamos categoría (Plomería)
      await tester.tap(find.byKey(const Key('category_1')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();

      // Verificamos que aparecen los servicios y profesionales disponibles para que el cliente elija
      expect(find.text('Profesionales y servicios disponibles'), findsOneWidget);
      expect(find.byKey(Key('service_${testService.id}')), findsOneWidget);

      // El cliente selecciona el servicio de su preferencia
      await tester.tap(find.byKey(Key('service_${testService.id}')));
      await tester.pumpAndSettle();

      // Verificamos que navegó directamente al detalle del servicio
      expect(navigatedLocation, '/services/${testService.id}');
      expect(find.text('SERVICE_DETAIL_SCREEN_${testService.id}'), findsOneWidget);
    },
  );
}
