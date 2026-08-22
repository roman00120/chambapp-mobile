import 'package:chambapp_mobile/core/errors/app_exception.dart';
import 'package:chambapp_mobile/core/theme/app_theme.dart';
import 'package:chambapp_mobile/features/jobs/domain/job_models.dart';
import 'package:chambapp_mobile/features/jobs/presentation/job_providers.dart';
import 'package:chambapp_mobile/features/jobs/presentation/searching_job_screen.dart';
import 'package:chambapp_mobile/features/professional/domain/professional_models.dart';
import 'package:chambapp_mobile/features/professional/presentation/professional_jobs_screen.dart';
import 'package:chambapp_mobile/features/professional/presentation/professional_providers.dart';
import 'package:chambapp_mobile/features/professional/presentation/widgets/invitation_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/m2_fakes.dart';
import '../helpers/m3_fakes.dart';

Widget _material(Widget child) =>
    MaterialApp(theme: AppTheme.light, home: child);

ProviderContainer _professionalContainer(
  FakeInvitationRepository invitations,
) => ProviderContainer(
  overrides: [
    availabilityRepositoryProvider.overrideWithValue(
      FakeAvailabilityRepository(value: available),
    ),
    jobInvitationRepositoryProvider.overrideWithValue(invitations),
    professionalJobRepositoryProvider.overrideWithValue(
      FakeProfessionalJobRepository(),
    ),
  ],
);

void main() {
  testWidgets('aceptar espera backend y muestra La chamba es tuya', (
    tester,
  ) async {
    final invitations = FakeInvitationRepository();
    final container = _professionalContainer(invitations);
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: _material(const ProfessionalJobsScreen()),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('accept_4')));
    await tester.pumpAndSettle();
    expect(invitations.acceptCalls, 1);
    expect(find.text('¡La chamba es tuya!'), findsWidgets);
  });

  testWidgets('409 JOB_ALREADY_TAKEN muestra mensaje y quita card', (
    tester,
  ) async {
    final invitations = FakeInvitationRepository()
      ..acceptError = const AppException(
        message: 'Conflicto',
        statusCode: 409,
        code: 'JOB_ALREADY_TAKEN',
      );
    final container = _professionalContainer(invitations);
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: _material(const ProfessionalJobsScreen()),
      ),
    );
    await tester.pumpAndSettle();
    invitations.values = const [];
    await tester.tap(find.byKey(const ValueKey('accept_4')));
    await tester.pumpAndSettle();
    expect(
      find.text('Esta chamba ya fue tomada por otro profesional.'),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('invitation_4')), findsNothing);
  });

  testWidgets('decline usa API y retira oportunidad sin cambiar availability', (
    tester,
  ) async {
    final invitations = FakeInvitationRepository();
    final container = _professionalContainer(invitations);
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: _material(const ProfessionalJobsScreen()),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('decline_4')));
    await tester.pumpAndSettle();
    expect(invitations.declineCalls, 1);
    expect(find.byKey(const ValueKey('invitation_4')), findsNothing);
    expect(container.read(availabilityProvider).value?.isAvailable, isTrue);
  });

  testWidgets('polling profesional pausa en background y refresca al volver', (
    tester,
  ) async {
    final invitations = FakeInvitationRepository();
    final container = _professionalContainer(invitations);
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: _material(const ProfessionalJobsScreen()),
      ),
    );
    await tester.pumpAndSettle();
    final initialCalls = invitations.getCalls;
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump(const Duration(seconds: 9));
    expect(invitations.getCalls, initialCalls);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    await tester.pump();
    expect(invitations.getCalls, greaterThan(initialCalls));
  });

  testWidgets('cliente pasa searching a matched con perfil público seguro', (
    tester,
  ) async {
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
    final container = ProviderContainer(
      overrides: [jobRepositoryProvider.overrideWithValue(jobs)],
    );
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
    await tester.pump(const Duration(seconds: 5));
    await tester.pump();
    expect(find.text('¡Encontramos un profesional!'), findsOneWidget);
    expect(find.text('Luis Profesional'), findsOneWidget);
    expect(find.textContaining('private@example.test'), findsNothing);
    expect(find.textContaining('WhatsApp'), findsNothing);
  });

  testWidgets('polling cliente pausa y consulta inmediatamente al reanudar', (
    tester,
  ) async {
    final jobs = FakeJobRepository();
    final container = ProviderContainer(
      overrides: [jobRepositoryProvider.overrideWithValue(jobs)],
    );
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
    final initialCalls = jobs.statusCalls;
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump(const Duration(seconds: 6));
    expect(jobs.statusCalls, initialCalls);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    await tester.pump();
    expect(jobs.statusCalls, greaterThan(initialCalls));
  });

  testWidgets('awaiting_quote muestra que el profesional prepara cotización', (
    tester,
  ) async {
    final jobs = FakeJobRepository(
      statuses: const [
        JobStatusModel(
          status: JobStatus.awaitingQuote,
          label: 'Esperando cotización',
          professional: testProfessional,
        ),
      ],
    );
    final container = ProviderContainer(
      overrides: [jobRepositoryProvider.overrideWithValue(jobs)],
    );
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
    await tester.pump();
    expect(
      find.text('Tu profesional está preparando la cotización.'),
      findsOneWidget,
    );
    expect(find.text('Luis Profesional'), findsOneWidget);
  });

  testWidgets('countdown refresca al llegar a cero sin declarar expiración', (
    tester,
  ) async {
    var refreshes = 0;
    await tester.pumpWidget(
      _material(
        InvitationCard(
          invitation: JobInvitationModel(
            id: 90,
            status: 'pending',
            distanceKm: 1.2,
            jobId: 91,
            title: 'Con tiempo',
            description: 'Oportunidad con vencimiento del backend.',
            expiresAt: DateTime.now().subtract(const Duration(seconds: 1)),
          ),
          processing: false,
          onAccept: () {},
          onDecline: () {},
          onExpired: () => refreshes++,
        ),
      ),
    );
    await tester.pump();
    expect(refreshes, 1);
    expect(find.text('Aceptar'), findsOneWidget);
  });
}
