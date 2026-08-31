import 'package:chambapp_mobile/app/providers.dart';
import 'package:chambapp_mobile/app/router.dart';
import 'package:chambapp_mobile/core/theme/app_theme.dart';
import 'package:chambapp_mobile/features/catalog/domain/catalog_models.dart';
import 'package:chambapp_mobile/features/catalog/presentation/catalog_providers.dart';
import 'package:chambapp_mobile/features/jobs/domain/job_models.dart';
import 'package:chambapp_mobile/features/jobs/presentation/job_providers.dart';
import 'package:chambapp_mobile/features/jobs/presentation/scheduled_job_screen.dart';
import 'package:chambapp_mobile/features/jobs/presentation/searching_job_screen.dart';
import 'package:chambapp_mobile/features/notifications/presentation/notification_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fakes.dart';
import '../helpers/m2_fakes.dart';

void main() {
  testWidgets(
    'E2E Navigation: Catalog -> ServiceDetailScreen -> Contratar servicio opens ServiceRequestScreen without 4-step wizard and navigates to Checkout',
    (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      const catalogService = ServiceModel(
        id: 42,
        title: 'Instalación de Calentador Solar',
        description: 'Servicio garantizado de instalación con tubería especializada.',
        price: '1500.00',
        priceType: 'fixed',
        currency: 'MXN',
        category: testCategory,
        professional: testProfessional,
      );

      const awaitingPaymentJob = JobModel(
        id: 101,
        title: 'Instalación de Calentador Solar',
        description: 'Servicio garantizado de instalación con tubería especializada.',
        status: JobStatus.awaitingPayment,
        statusLabel: 'Pendiente de pago',
        category: testCategory,
      );

      final fakeJobs = FakeJobRepository()
        ..scheduledJobResult = awaitingPaymentJob
        ..job = awaitingPaymentJob;
      final fakeServices = FakeServiceRepository()..services = [catalogService];

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

      // Iniciamos sesión como cliente
      await container.read(authControllerProvider.notifier).login(
        email: 'ana@example.test',
        password: 'secret',
      );

      final router = container.read(routerProvider);

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

      // Estamos en ClientHomeScreen: navegamos al detalle del servicio 42
      router.push('/services/42');
      await tester.pumpAndSettle();

      // 1. Verificamos que estamos en ServiceDetailScreen
      expect(find.text('Detalle del servicio'), findsOneWidget);
      expect(find.text('Instalación de Calentador Solar'), findsOneWidget);
      expect(find.byKey(const Key('request_service')), findsOneWidget);
      expect(find.text('Contratar servicio'), findsOneWidget);

      // 2. Tocamos el botón "Contratar servicio"
      await tester.tap(find.byKey(const Key('request_service')));
      await tester.pumpAndSettle();

      // 3. Verificamos que la pantalla que abre es ServiceRequestScreen y NUNCA ScheduledJobScreen
      expect(find.text('Contratar servicio'), findsOneWidget);
      expect(find.byType(ScheduledJobScreen), findsNothing);

      // Verificamos que NO existen los pasos de wizard
      expect(find.textContaining('Paso 1 de 4'), findsNothing);
      expect(find.textContaining('Paso 2 de 4'), findsNothing);
      expect(find.textContaining('Paso 3 de 4'), findsNothing);
      expect(find.textContaining('Paso 4 de 4'), findsNothing);
      expect(find.textContaining('Paso '), findsNothing);
      expect(find.text('¿Qué necesitas?'), findsNothing);

      // 4. Llenamos los datos mínimos requeridos de ubicación
      await tester.enterText(
        find.byKey(const Key('request_address')),
        'Av. Chapultepec 220',
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

      // 5. Tocamos "Confirmar contratación"
      await tester.tap(find.byKey(const Key('confirm_service_request')));
      await tester.pumpAndSettle();

      // 6. Verificamos que se creó el trabajo con el serviceId correspondiente
      expect(fakeJobs.createScheduledCalls, 1);
      expect(fakeJobs.lastScheduledInput?.serviceId, 42);
      expect(fakeJobs.lastScheduledInput?.title, 'Instalación de Calentador Solar');

      // 7. Verificamos que navegó directamente a Checkout y NUNCA a Radar / Searching
      expect(find.byType(SearchingJobScreen), findsNothing);
      expect(find.textContaining('Buscando'), findsNothing);
      expect(find.text('Pago de la chamba'), findsOneWidget);
      expect(find.text('Pagar Chamba'), findsOneWidget);
    },
  );
}
