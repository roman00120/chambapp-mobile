import 'dart:async';

import 'package:chambapp_mobile/core/errors/app_exception.dart';
import 'package:chambapp_mobile/features/professional/domain/professional_models.dart';
import 'package:chambapp_mobile/features/professional/presentation/professional_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/m3_fakes.dart';

ProviderContainer _container(
  FakeInvitationRepository invitations, {
  FakeProfessionalJobRepository? jobs,
}) => ProviderContainer(
  overrides: [
    jobInvitationRepositoryProvider.overrideWithValue(invitations),
    professionalJobRepositoryProvider.overrideWithValue(
      jobs ?? FakeProfessionalJobRepository(),
    ),
  ],
);

void main() {
  test('accept success quita invitación y devuelve Job asignado', () async {
    final repository = FakeInvitationRepository();
    final container = _container(repository);
    addTearDown(container.dispose);
    await container.read(jobInvitationsProvider.future);

    final result = await container
        .read(jobInvitationsProvider.notifier)
        .accept(invitation);

    expect(result.outcome, InvitationActionOutcome.accepted);
    expect(result.job?.id, professionalJob.id);
    expect(container.read(jobInvitationsProvider).value!.items, isEmpty);
  });

  test('doble tap solo envía una aceptación', () async {
    final repository = FakeInvitationRepository()
      ..acceptCompleter = Completer();
    final container = _container(repository);
    addTearDown(container.dispose);
    await container.read(jobInvitationsProvider.future);

    final first = container
        .read(jobInvitationsProvider.notifier)
        .accept(invitation);
    final second = await container
        .read(jobInvitationsProvider.notifier)
        .accept(invitation);
    expect(second.outcome, InvitationActionOutcome.failed);
    expect(repository.acceptCalls, 1);
    repository.acceptCompleter!.complete(professionalJob);
    expect((await first).succeeded, isTrue);
  });

  test(
    'JOB_ALREADY_TAKEN muestra mensaje estable y retira oportunidad',
    () async {
      final repository = FakeInvitationRepository()
        ..acceptError = const AppException(
          message: 'Conflicto',
          statusCode: 409,
          code: 'JOB_ALREADY_TAKEN',
        )
        ..values = const [];
      final container = _container(repository);
      addTearDown(container.dispose);
      repository.values = const [invitation];
      await container.read(jobInvitationsProvider.future);
      repository.values = const [];

      final result = await container
          .read(jobInvitationsProvider.notifier)
          .accept(invitation);
      expect(result.outcome, InvitationActionOutcome.alreadyTaken);
      expect(result.message, 'Esta chamba ya fue tomada por otro profesional.');
      expect(container.read(jobInvitationsProvider).value!.items, isEmpty);
    },
  );

  test('PROFESSIONAL_BUSY no declara victoria ni reintenta', () async {
    final repository = FakeInvitationRepository()
      ..acceptError = const AppException(
        message: 'Busy',
        statusCode: 409,
        code: 'PROFESSIONAL_BUSY',
      );
    final container = _container(repository);
    addTearDown(container.dispose);
    await container.read(jobInvitationsProvider.future);

    final result = await container
        .read(jobInvitationsProvider.notifier)
        .accept(invitation);
    expect(result.outcome, InvitationActionOutcome.busy);
    expect(result.message, 'Ya tienes una chamba activa.');
    expect(repository.acceptCalls, 1);
    expect(container.read(jobInvitationsProvider).value!.items, hasLength(1));
  });

  test('polling deduplica y agrega una invitación nueva', () async {
    const second = JobInvitationModel(
      id: 8,
      status: 'pending',
      distanceKm: 3.2,
      jobId: 22,
      title: 'Segunda',
      description: 'Segunda oportunidad disponible.',
    );
    final repository = FakeInvitationRepository()
      ..getResponses = const [
        [invitation, invitation],
        [second, invitation, invitation],
      ];
    final container = _container(repository);
    addTearDown(container.dispose);
    final initial = await container.read(jobInvitationsProvider.future);
    expect(initial.items, hasLength(1));

    await container.read(jobInvitationsProvider.notifier).refresh(silent: true);
    final refreshed = container.read(jobInvitationsProvider).value!;
    expect(refreshed.items.map((item) => item.id), [8, 4]);
  });

  test('timeout ambiguo recupera victoria consultando trabajos', () async {
    final repository = FakeInvitationRepository()
      ..acceptError = const AppException(message: 'Revisa tu conexión')
      ..values = const [];
    final jobs = FakeProfessionalJobRepository()
      ..values = const [professionalJob];
    final container = _container(repository, jobs: jobs);
    addTearDown(container.dispose);
    repository.values = const [invitation];
    await container.read(jobInvitationsProvider.future);
    repository.values = const [];

    final result = await container
        .read(jobInvitationsProvider.notifier)
        .accept(invitation);
    expect(result.outcome, InvitationActionOutcome.accepted);
    expect(result.job?.id, invitation.jobId);
  });

  test('fallo de red sin confirmación no muestra victoria falsa', () async {
    final repository = FakeInvitationRepository()
      ..acceptError = const AppException(message: 'Sin conexión');
    final jobs = FakeProfessionalJobRepository()..values = const [];
    final container = _container(repository, jobs: jobs);
    addTearDown(container.dispose);
    await container.read(jobInvitationsProvider.future);

    final result = await container
        .read(jobInvitationsProvider.notifier)
        .accept(invitation);
    expect(result.outcome, InvitationActionOutcome.networkUnconfirmed);
    expect(result.succeeded, isFalse);
    expect(container.read(jobInvitationsProvider).value!.items, hasLength(1));
  });

  test('invitación expirada o lost no se incluye entre activas', () async {
    final expired = JobInvitationModel(
      id: 30,
      status: 'expired',
      distanceKm: 1,
      jobId: 31,
      title: 'Expirada',
      description: 'Ya no disponible',
      expiresAt: DateTime.now().subtract(const Duration(seconds: 1)),
    );
    const lost = JobInvitationModel(
      id: 32,
      status: 'lost',
      distanceKm: 1,
      jobId: 33,
      title: 'Perdida',
      description: 'Ganó otro profesional',
    );
    final repository = FakeInvitationRepository()..values = [expired, lost];
    final container = _container(repository);
    addTearDown(container.dispose);
    final feed = await container.read(jobInvitationsProvider.future);
    expect(feed.items, isEmpty);
  });
}
