import 'package:chambapp_mobile/app/providers.dart';
import 'package:chambapp_mobile/core/errors/api_error_mapper.dart';
import 'package:chambapp_mobile/core/errors/app_exception.dart';
import 'package:chambapp_mobile/features/jobs/domain/job_models.dart';
import 'package:chambapp_mobile/features/professional/data/professional_repositories_impl.dart';
import 'package:chambapp_mobile/features/professional/domain/professional_models.dart';
import 'package:chambapp_mobile/features/professional/domain/professional_repositories.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final professionalProfileRepositoryProvider =
    Provider<ProfessionalProfileRepository>(
      (ref) => ApiProfessionalProfileRepository(
        ref.watch(dioProvider),
        const ApiErrorMapper(),
      ),
    );
final identityVerificationRepositoryProvider =
    Provider<IdentityVerificationRepository>(
      (ref) => ApiIdentityVerificationRepository(
        ref.watch(dioProvider),
        const ApiErrorMapper(),
      ),
    );

final identityVerificationProvider = FutureProvider<IdentityVerificationModel>(
  (ref) => ref.watch(identityVerificationRepositoryProvider).getStatus(),
);
final availabilityRepositoryProvider = Provider<AvailabilityRepository>(
  (ref) =>
      ApiAvailabilityRepository(ref.watch(dioProvider), const ApiErrorMapper()),
);
final professionalServiceRepositoryProvider =
    Provider<ProfessionalServiceRepository>(
      (ref) => ApiProfessionalServiceRepository(
        ref.watch(dioProvider),
        const ApiErrorMapper(),
      ),
    );
final jobInvitationRepositoryProvider = Provider<JobInvitationRepository>(
  (ref) => ApiJobInvitationRepository(
    ref.watch(dioProvider),
    const ApiErrorMapper(),
  ),
);
final professionalJobRepositoryProvider = Provider<ProfessionalJobRepository>(
  (ref) => ApiProfessionalJobRepository(
    ref.watch(dioProvider),
    const ApiErrorMapper(),
  ),
);

final professionalProfileProvider =
    AsyncNotifierProvider<
      ProfessionalProfileController,
      ProfessionalProfileModel
    >(ProfessionalProfileController.new);

final class ProfessionalProfileController
    extends AsyncNotifier<ProfessionalProfileModel> {
  @override
  Future<ProfessionalProfileModel> build() =>
      ref.watch(professionalProfileRepositoryProvider).getProfile();

  Future<void> saveProfile(ProfessionalProfileInput input) async {
    state = const AsyncLoading<ProfessionalProfileModel>();
    state = await AsyncValue.guard(
      () =>
          ref.read(professionalProfileRepositoryProvider).updateProfile(input),
    );
  }
}

final availabilityProvider =
    AsyncNotifierProvider<AvailabilityController, AvailabilityModel>(
      AvailabilityController.new,
    );

final class AvailabilityController extends AsyncNotifier<AvailabilityModel> {
  @override
  Future<AvailabilityModel> build() =>
      ref.watch(availabilityRepositoryProvider).getAvailability();

  Future<bool> saveAvailability({
    required bool isAvailable,
    required int serviceRadiusKm,
    double? latitude,
    double? longitude,
  }) async {
    state = const AsyncLoading<AvailabilityModel>();
    try {
      final value = await ref
          .read(availabilityRepositoryProvider)
          .updateAvailability(
            isAvailable: isAvailable,
            serviceRadiusKm: serviceRadiusKm,
            latitude: latitude,
            longitude: longitude,
          );
      state = AsyncData(value);
      ref.invalidate(professionalProfileProvider);
      return true;
    } catch (error, stack) {
      state = AsyncError<AvailabilityModel>(error, stack);
      return false;
    }
  }
}

final professionalServicesProvider =
    AsyncNotifierProvider<
      ProfessionalServicesController,
      List<ProfessionalServiceModel>
    >(ProfessionalServicesController.new);

final class ProfessionalServicesController
    extends AsyncNotifier<List<ProfessionalServiceModel>> {
  @override
  Future<List<ProfessionalServiceModel>> build() =>
      ref.watch(professionalServiceRepositoryProvider).getServices();

  Future<void> create(ProfessionalServiceInput input) async {
    await ref.read(professionalServiceRepositoryProvider).create(input);
    ref.invalidateSelf();
    await future;
  }

  Future<void> updateService(int id, ProfessionalServiceInput input) async {
    await ref.read(professionalServiceRepositoryProvider).update(id, input);
    ref.invalidateSelf();
    await future;
  }

  Future<void> delete(int id) async {
    await ref.read(professionalServiceRepositoryProvider).delete(id);
    ref.invalidateSelf();
    await future;
  }
}

final jobInvitationsProvider =
    AsyncNotifierProvider<JobInvitationsController, InvitationFeedState>(
      JobInvitationsController.new,
    );

final class JobInvitationsController
    extends AsyncNotifier<InvitationFeedState> {
  @override
  Future<InvitationFeedState> build() async => InvitationFeedState(
    items: _dedupe(
      await ref.watch(jobInvitationRepositoryProvider).getInvitations(),
    ),
  );

  Future<void> refresh({bool silent = false}) async {
    final previous = state.value ?? const InvitationFeedState();
    if (!silent) state = const AsyncLoading<InvitationFeedState>();
    try {
      final items = _dedupe(
        await ref.read(jobInvitationRepositoryProvider).getInvitations(),
      );
      state = AsyncData(
        previous.copyWith(
          items: items,
          consecutiveErrors: 0,
          clearMessage: true,
        ),
      );
    } catch (error, stack) {
      if (silent) {
        final pollingMessage = error is AppException && error.statusCode == 429
            ? error.message
            : 'Perdiste conexión. Intentaremos actualizar cuando vuelva.';
        state = AsyncData(
          previous.copyWith(
            consecutiveErrors: previous.consecutiveErrors + 1,
            message: pollingMessage,
          ),
        );
      } else {
        state = AsyncError<InvitationFeedState>(error, stack);
      }
    }
  }

  Future<InvitationActionResult> accept(JobInvitationModel invitation) async {
    final current = state.value ?? const InvitationFeedState();
    if (current.processingIds.contains(invitation.id)) {
      return const InvitationActionResult(
        outcome: InvitationActionOutcome.failed,
        message: 'La aceptación ya está en proceso.',
      );
    }
    _setProcessing(invitation.id, true);
    try {
      final job = await ref
          .read(jobInvitationRepositoryProvider)
          .acceptInvitation(invitation.id);
      _remove(invitation.id);
      ref.invalidate(professionalJobsProvider(null));
      return InvitationActionResult(
        outcome: InvitationActionOutcome.accepted,
        message: '¡La chamba es tuya!',
        job: job,
      );
    } on AppException catch (error) {
      if (error.statusCode == null) return _recoverAmbiguous(invitation);
      final result = switch (error.code) {
        'JOB_ALREADY_TAKEN' => const InvitationActionResult(
          outcome: InvitationActionOutcome.alreadyTaken,
          message: 'Esta chamba ya fue tomada por otro profesional.',
        ),
        'PROFESSIONAL_BUSY' => const InvitationActionResult(
          outcome: InvitationActionOutcome.busy,
          message: 'Ya tienes una chamba activa.',
        ),
        'LOCATION_STALE' => const InvitationActionResult(
          outcome: InvitationActionOutcome.locationStale,
          message: 'Actualiza tu ubicación antes de aceptar.',
        ),
        'INVITATION_UNAVAILABLE' ||
        'INVITATION_EXPIRED' => const InvitationActionResult(
          outcome: InvitationActionOutcome.expired,
          message: 'Esta oportunidad ya expiró.',
        ),
        _ => InvitationActionResult(
          outcome: InvitationActionOutcome.failed,
          message: error.message,
        ),
      };
      if ({
        InvitationActionOutcome.alreadyTaken,
        InvitationActionOutcome.expired,
      }.contains(result.outcome)) {
        _remove(invitation.id);
        await refresh(silent: true);
      }
      return result;
    } finally {
      _setProcessing(invitation.id, false);
    }
  }

  Future<InvitationActionResult> decline(JobInvitationModel invitation) async {
    final current = state.value ?? const InvitationFeedState();
    if (current.processingIds.contains(invitation.id)) {
      return const InvitationActionResult(
        outcome: InvitationActionOutcome.failed,
        message: 'La operación ya está en proceso.',
      );
    }
    _setProcessing(invitation.id, true);
    try {
      await ref
          .read(jobInvitationRepositoryProvider)
          .declineInvitation(invitation.id);
      _remove(invitation.id);
      return const InvitationActionResult(
        outcome: InvitationActionOutcome.declined,
        message: 'Oportunidad descartada.',
      );
    } on AppException catch (error) {
      if (error.code == 'INVITATION_UNAVAILABLE') {
        _remove(invitation.id);
        return const InvitationActionResult(
          outcome: InvitationActionOutcome.expired,
          message: 'Esta oportunidad ya expiró.',
        );
      }
      return InvitationActionResult(
        outcome: InvitationActionOutcome.failed,
        message: error.statusCode == null
            ? 'No pudimos confirmar el rechazo. Actualiza para verificar.'
            : error.message,
      );
    } finally {
      _setProcessing(invitation.id, false);
    }
  }

  Future<InvitationActionResult> _recoverAmbiguous(
    JobInvitationModel invitation,
  ) async {
    List<JobInvitationModel> invitations = const [];
    List<JobModel> jobs = const [];
    try {
      final results = await Future.wait([
        ref.read(jobInvitationRepositoryProvider).getInvitations(),
        ref.read(professionalJobRepositoryProvider).getJobs(),
      ]);
      invitations = results[0] as List<JobInvitationModel>;
      jobs = results[1] as List<JobModel>;
    } catch (_) {
      return const InvitationActionResult(
        outcome: InvitationActionOutcome.networkUnconfirmed,
        message: 'No pudimos confirmar la aceptación. Actualiza antes de reintentar.',
      );
    }
    final assigned = jobs
        .where((job) => job.id == invitation.jobId)
        .firstOrNull;
    if (assigned != null) {
      _remove(invitation.id);
      ref.invalidate(professionalJobsProvider(null));
      return InvitationActionResult(
        outcome: InvitationActionOutcome.accepted,
        message: '¡La chamba es tuya!',
        job: assigned,
      );
    }
    final stillAvailable = invitations.any(
      (item) => item.id == invitation.id && item.actionable,
    );
    state = AsyncData(
      (state.value ?? const InvitationFeedState()).copyWith(
        items: _dedupe(invitations),
      ),
    );
    return InvitationActionResult(
      outcome: stillAvailable
          ? InvitationActionOutcome.networkUnconfirmed
          : InvitationActionOutcome.expired,
      message: stillAvailable
          ? 'No pudimos confirmar la aceptación. Actualiza antes de reintentar.'
          : 'Esta oportunidad ya no está disponible.',
    );
  }

  void _setProcessing(int id, bool processing) {
    final value = state.value;
    if (value == null) return;
    final ids = {...value.processingIds};
    processing ? ids.add(id) : ids.remove(id);
    state = AsyncData(value.copyWith(processingIds: ids));
  }

  void _remove(int id) {
    final value = state.value;
    if (value == null) return;
    state = AsyncData(
      value.copyWith(
        items: value.items.where((item) => item.id != id).toList(),
      ),
    );
  }

  List<JobInvitationModel> _dedupe(List<JobInvitationModel> items) => [
    for (final item in {for (final item in items) item.id: item}.values)
      if (item.actionable) item,
  ];
}

final professionalJobsProvider =
    FutureProvider.family<List<JobModel>, JobStatus?>((ref, status) {
      final userId = ref.watch(
        authControllerProvider.select((state) => state.user?.id),
      );
      if (userId == null) return Future.value(const []);
      return ref
          .watch(professionalJobRepositoryProvider)
          .getJobs(status: status);
    });
final earningsSummaryProvider = Provider<EarningsSummaryModel>(
  (ref) => EarningsSummaryModel.unavailable,
);
