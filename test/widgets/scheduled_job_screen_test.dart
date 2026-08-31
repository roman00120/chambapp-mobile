import 'package:chambapp_mobile/app/providers.dart';
import 'package:chambapp_mobile/core/theme/app_theme.dart';
import 'package:chambapp_mobile/features/catalog/domain/catalog_models.dart';
import 'package:chambapp_mobile/features/catalog/domain/catalog_repositories.dart';
import 'package:chambapp_mobile/features/catalog/presentation/catalog_providers.dart';
import 'package:chambapp_mobile/features/jobs/presentation/job_providers.dart';
import 'package:chambapp_mobile/features/jobs/presentation/scheduled_job_screen.dart';
import 'package:chambapp_mobile/features/notifications/presentation/notification_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fakes.dart';
import '../helpers/m2_fakes.dart';

const testCategory2 = CategoryModel(
  id: 2,
  name: 'Cerrajería',
  slug: 'cerrajeria',
);

final class MultiCategoryRepository implements CategoryRepository {
  @override
  Future<List<CategoryModel>> getCategories() async => const [
    testCategory,
    testCategory2,
  ];
}

void main() {
  testWidgets(
    'ScheduledJobScreen: touching a category updates selection, visual state and allows Continuar',
    (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final fakeJobs = FakeJobRepository();
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
          categoryRepositoryProvider.overrideWithValue(MultiCategoryRepository()),
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
          child: MaterialApp(
            theme: AppTheme.light,
            home: const ScheduledJobScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Al inicio no hay categoría seleccionada
      expect(find.text('Programar chamba'), findsOneWidget);
      expect(find.byKey(const Key('category_1')), findsOneWidget);
      expect(find.byKey(const Key('category_2')), findsOneWidget);
      expect(find.text('Seleccionada: Plomería'), findsNothing);
      expect(find.text('Seleccionada: Cerrajería'), findsNothing);

      // Si pulsamos Continuar sin seleccionar, no avanza del paso 1
      await tester.tap(find.byKey(const Key('wizard_next')));
      await tester.pumpAndSettle();
      expect(find.text('Paso 1 de 4'), findsOneWidget);
      expect(find.text('¿Qué necesitas?'), findsOneWidget);

      // Tocamos Cerrajería (category_2)
      await tester.tap(find.byKey(const Key('category_2')));
      await tester.pumpAndSettle(const Duration(seconds: 4));

      // Debe mostrar la selección activa
      expect(find.text('Seleccionada: Cerrajería'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsOneWidget);

      // Tocamos Plomería (category_1)
      await tester.tap(find.byKey(const Key('category_1')));
      await tester.pumpAndSettle();

      // Debe cambiar la selección a Plomería
      expect(find.text('Seleccionada: Plomería'), findsOneWidget);
      expect(find.text('Seleccionada: Cerrajería'), findsNothing);
      expect(find.byIcon(Icons.check_circle), findsOneWidget);

      // Pulsamos Continuar y avanza a Paso 2 (Descripción)
      await tester.tap(find.byKey(const Key('wizard_next')));
      await tester.pumpAndSettle();

      expect(find.text('Paso 2 de 4'), findsOneWidget);
      expect(find.text('Descripción'), findsOneWidget);
      expect(find.byKey(const Key('scheduled_description')), findsOneWidget);
    },
  );
}
