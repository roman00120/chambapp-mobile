import 'package:chambapp_mobile/app/providers.dart';
import 'package:chambapp_mobile/app/router.dart';
import 'package:chambapp_mobile/core/errors/app_exception.dart';
import 'package:chambapp_mobile/core/theme/app_theme.dart';
import 'package:chambapp_mobile/features/catalog/presentation/catalog_providers.dart';
import 'package:chambapp_mobile/features/location/presentation/location_controller.dart';
import 'package:chambapp_mobile/features/notifications/presentation/notification_controller.dart';
import 'package:chambapp_mobile/features/professional/domain/professional_models.dart';
import 'package:chambapp_mobile/features/professional/domain/professional_repositories.dart';
import 'package:chambapp_mobile/features/professional/presentation/availability_screen.dart';
import 'package:chambapp_mobile/features/professional/presentation/edit_professional_profile_screen.dart';
import 'package:chambapp_mobile/features/professional/presentation/professional_home_screen.dart';
import 'package:chambapp_mobile/features/professional/presentation/professional_jobs_screen.dart';
import 'package:chambapp_mobile/features/professional/presentation/professional_profile_screen.dart';
import 'package:chambapp_mobile/features/professional/presentation/professional_providers.dart';
import 'package:chambapp_mobile/features/professional/presentation/professional_services_screen.dart';
import 'package:chambapp_mobile/features/professional/presentation/service_form_screen.dart';
import 'package:chambapp_mobile/features/professional/presentation/widgets/availability_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/m2_fakes.dart';
import '../helpers/m3_fakes.dart';

Widget _material(Widget child) =>
    MaterialApp(theme: AppTheme.light, home: child);

Future<ProviderContainer> _container({
  FakeAvailabilityRepository? availability,
  FakeProfessionalServiceRepository? services,
  FakeInvitationRepository? invitations,
}) async {
  final container = ProviderContainer(
    overrides: [
      authRepositoryProvider.overrideWithValue(
        FakeProfessionalAuthRepository(),
      ),
      professionalProfileRepositoryProvider.overrideWithValue(
        FakeProfessionalProfileRepository(),
      ),
      availabilityRepositoryProvider.overrideWithValue(
        availability ?? FakeAvailabilityRepository(),
      ),
      professionalServiceRepositoryProvider.overrideWithValue(
        services ?? FakeProfessionalServiceRepository(),
      ),
      jobInvitationRepositoryProvider.overrideWithValue(
        invitations ?? FakeInvitationRepository(),
      ),
      professionalJobRepositoryProvider.overrideWithValue(
        FakeProfessionalJobRepository(),
      ),
      categoryRepositoryProvider.overrideWithValue(FakeCategoryRepository()),
      locationServiceProvider.overrideWithValue(FakeLocationService()),
      notificationRepositoryProvider.overrideWithValue(
        FakeNotificationRepository(),
      ),
    ],
  );
  await container
      .read(authControllerProvider.notifier)
      .login(email: 'carlos@example.test', password: 'secret');
  return container;
}

void main() {
  testWidgets('AvailabilityCard cambia unavailable a available', (
    tester,
  ) async {
    bool? requested;
    await tester.pumpWidget(
      _material(
        AvailabilityCard(
          availability: unavailable,
          loading: false,
          onChanged: (value) => requested = value,
        ),
      ),
    );
    expect(find.text('No disponible'), findsOneWidget);
    await tester.tap(find.byKey(const Key('availability_switch')));
    expect(requested, isTrue);
  });

  testWidgets('busy muestra Ocupado y no permite fingir disponibilidad', (
    tester,
  ) async {
    await tester.pumpWidget(
      _material(
        const AvailabilityCard(
          availability: busy,
          loading: false,
          onChanged: null,
        ),
      ),
    );
    expect(find.text('Ocupado'), findsOneWidget);
    expect(find.text('Actualmente tienes una chamba activa.'), findsOneWidget);
    final switchWidget = tester.widget<Switch>(find.byType(Switch));
    expect(switchWidget.onChanged, isNull);
  });

  testWidgets('home profesional muestra estado, oportunidades y resumen', (
    tester,
  ) async {
    final container = await _container();
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: _material(const ProfessionalHomeScreen()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Hola, Carlos'), findsOneWidget);
    expect(find.text('¿Listo para una nueva chamba?'), findsOneWidget);
    expect(find.text('No disponible'), findsOneWidget);
    expect(find.text('Chambas cerca de ti'), findsOneWidget);
    expect(find.textContaining('Aprox. 2.8 km'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Resumen profesional'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Resumen profesional'), findsOneWidget);
  });

  testWidgets('routing por rol abre shell profesional con cinco destinos', (
    tester,
  ) async {
    final container = await _container();
    addTearDown(container.dispose);
    final router = container.read(routerProvider);
    addTearDown(router.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(ProfessionalHomeScreen), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('Inicio'), findsOneWidget);
    expect(find.text('Chambas'), findsOneWidget);
    expect(find.text('Servicios'), findsOneWidget);
    expect(find.text('Ganancias'), findsOneWidget);
    expect(find.text('Perfil'), findsOneWidget);

    router.go('/client/home');
    await tester.pumpAndSettle();
    expect(find.byType(ProfessionalHomeScreen), findsOneWidget);
  });

  testWidgets('LOCATION_STALE muestra feedback y CTA de ubicación', (
    tester,
  ) async {
    final repository = FakeAvailabilityRepository(
      value: available,
      error: const AppException(
        message: 'Actualiza tu ubicación antes de ponerte disponible.',
        statusCode: 409,
        code: 'LOCATION_STALE',
      ),
    );
    final container = await _container(availability: repository);
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: _material(const AvailabilityScreen()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Actualizar ubicación'), findsOneWidget);
    await tester.tap(find.byKey(const Key('availability_switch')));
    await tester.pumpAndSettle();
    expect(find.textContaining('Actualiza tu ubicación'), findsWidgets);
  });

  testWidgets('servicios lista estado y formulario usa categorías reales', (
    tester,
  ) async {
    final container = await _container();
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: _material(const ProfessionalServicesScreen()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Reparación de fugas'), findsOneWidget);
    expect(find.text('Activo'), findsOneWidget);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: _material(const ServiceFormScreen()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Crear servicio'), findsOneWidget);
    await tester.tap(find.byType(DropdownButtonFormField<int>));
    await tester.pumpAndSettle();
    expect(find.text('Plomería'), findsOneWidget);
    await tester.tap(find.text('Plomería'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.textContaining('comisión del 15%'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.textContaining('comisión del 15%'), findsOneWidget);
  });

  testWidgets('perfil carga datos y etiqueta de verificación', (tester) async {
    final container = await _container();
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: _material(const ProfessionalProfileScreen()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Carlos Ramírez'), findsOneWidget);
    expect(find.text('Perfil habilitado'), findsOneWidget);
    expect(find.text('8 años de experiencia'), findsOneWidget);
  });

  testWidgets('chambas muestra invitación inmediata sin datos de contacto', (
    tester,
  ) async {
    final container = await _container(
      availability: FakeAvailabilityRepository(value: available),
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: _material(const ProfessionalJobsScreen()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('Ahora'), findsOneWidget);
    expect(find.textContaining('Aprox. 2.8 km'), findsOneWidget);
    expect(find.text('Aceptar'), findsOneWidget);
    expect(find.text('No me interesa'), findsOneWidget);
    expect(find.textContaining('teléfono'), findsNothing);
    expect(find.textContaining('WhatsApp'), findsNothing);
  });

  for (final size in const [
    Size(320, 568),
    Size(360, 800),
    Size(390, 844),
    Size(412, 915),
    Size(800, 1024),
  ]) {
    testWidgets(
      'home profesional responde en ${size.width.toInt()}x${size.height.toInt()}',
      (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final container = await _container();
        addTearDown(container.dispose);
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: _material(const ProfessionalHomeScreen()),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.text('Hola, Carlos'), findsOneWidget);
      },
    );
  }

  testWidgets(
    'editar perfil profesional muestra errores 422 y los limpia al escribir',
    (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final fakeProfileRepo = _FailingProfileRepository();
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(
            FakeProfessionalAuthRepository(),
          ),
          professionalProfileRepositoryProvider.overrideWithValue(
            fakeProfileRepo,
          ),
          availabilityRepositoryProvider.overrideWithValue(
            FakeAvailabilityRepository(),
          ),
          professionalServiceRepositoryProvider.overrideWithValue(
            FakeProfessionalServiceRepository(),
          ),
          jobInvitationRepositoryProvider.overrideWithValue(
            FakeInvitationRepository(),
          ),
          professionalJobRepositoryProvider.overrideWithValue(
            FakeProfessionalJobRepository(),
          ),
          categoryRepositoryProvider.overrideWithValue(
            FakeCategoryRepository(),
          ),
          locationServiceProvider.overrideWithValue(FakeLocationService()),
          notificationRepositoryProvider.overrideWithValue(
            FakeNotificationRepository(),
          ),
        ],
      );
      addTearDown(container.dispose);
      await container
          .read(authControllerProvider.notifier)
          .login(email: 'carlos@example.test', password: 'secret');

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: _material(const EditProfessionalProfileScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Carlos Ramírez'), findsOneWidget);
      expect(find.text('5512345678'), findsOneWidget);

      await tester.tap(find.text('Guardar perfil'));
      await tester.pumpAndSettle();

      expect(find.text('Escribe tu nombre.'), findsOneWidget);
      expect(find.text('Indica tus años de experiencia.'), findsOneWidget);

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Carlos Ramírez'),
        'Carlos R.',
      );
      await tester.pump();
      expect(find.text('Escribe tu nombre.'), findsNothing);
      expect(find.text('Indica tus años de experiencia.'), findsOneWidget);
    },
  );
}

class _FailingProfileRepository implements ProfessionalProfileRepository {
  @override
  Future<ProfessionalProfileModel> getProfile() async => professionalProfile;

  @override
  Future<ProfessionalProfileModel> updateProfile(
    ProfessionalProfileInput input,
  ) async {
    throw const AppException(
      message: 'Revisa los datos ingresados.',
      statusCode: 422,
      fieldErrors: {
        'name': 'Escribe tu nombre.',
        'experience_years': 'Indica tus años de experiencia.',
      },
    );
  }
}
