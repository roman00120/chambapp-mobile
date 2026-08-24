import 'package:chambapp_mobile/features/jobs/domain/job_models.dart';
import 'package:chambapp_mobile/features/professional/domain/professional_models.dart';

abstract interface class ProfessionalProfileRepository {
  Future<ProfessionalProfileModel> getProfile();
  Future<ProfessionalProfileModel> updateProfile(
    ProfessionalProfileInput input,
  );
}

abstract interface class IdentityVerificationRepository {
  Future<IdentityVerificationModel> getStatus();
}

abstract interface class AvailabilityRepository {
  Future<AvailabilityModel> getAvailability();
  Future<AvailabilityModel> updateAvailability({
    required bool isAvailable,
    required int serviceRadiusKm,
    double? latitude,
    double? longitude,
  });
}

abstract interface class ProfessionalServiceRepository {
  Future<List<ProfessionalServiceModel>> getServices({int page = 1});
  Future<ProfessionalServiceModel> create(ProfessionalServiceInput input);
  Future<ProfessionalServiceModel> update(
    int id,
    ProfessionalServiceInput input,
  );
  Future<void> delete(int id);
}

abstract interface class JobInvitationRepository {
  Future<List<JobInvitationModel>> getInvitations({int page = 1});
  Future<JobModel> acceptInvitation(int invitationId);
  Future<void> declineInvitation(int invitationId);
}

abstract interface class ProfessionalJobRepository {
  Future<List<JobModel>> getJobs({JobStatus? status, int page = 1});
}
