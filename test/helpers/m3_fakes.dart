import 'dart:async';

import 'package:chambapp_mobile/features/auth/domain/auth_repository.dart';
import 'package:chambapp_mobile/features/auth/domain/user.dart';
import 'package:chambapp_mobile/features/jobs/domain/job_models.dart';
import 'package:chambapp_mobile/features/location/domain/location_service.dart';
import 'package:chambapp_mobile/features/professional/domain/professional_models.dart';
import 'package:chambapp_mobile/features/professional/domain/professional_repositories.dart';

const professionalUser = User(
  id: 20,
  name: 'Carlos Ramírez',
  role: UserRole.professional,
  email: 'carlos@example.test',
  phone: '5512345678',
  status: 'active',
);
const professionalSession = AuthSession(
  token: 'professional-token',
  user: professionalUser,
);
const professionalProfile = ProfessionalProfileModel(
  id: 5,
  name: 'Carlos Ramírez',
  rating: 4.8,
  totalReviews: 18,
  completedJobs: 31,
  verification: ProfessionalVerification.verified,
  isAvailable: false,
  bio: 'Plomero profesional con amplia experiencia.',
  experienceYears: 8,
  city: 'Guadalajara',
  state: 'Jalisco',
  serviceRadiusKm: 10,
);
const available = AvailabilityModel(
  isAvailable: true,
  availabilityStatus: 'available',
  serviceRadiusKm: 10,
  latitude: 20.67,
  longitude: -103.34,
);
const unavailable = AvailabilityModel(
  isAvailable: false,
  availabilityStatus: 'available',
  serviceRadiusKm: 10,
);
const busy = AvailabilityModel(
  isAvailable: true,
  availabilityStatus: 'busy',
  serviceRadiusKm: 10,
  latitude: 20.67,
  longitude: -103.34,
);
const professionalService = ProfessionalServiceModel(
  id: 9,
  title: 'Reparación de fugas',
  description: 'Reparación profesional de fugas residenciales.',
  priceType: ProfessionalPriceType.fixed,
  price: '500.00',
  currency: 'MXN',
  isActive: true,
);
const invitation = JobInvitationModel(
  id: 4,
  status: 'viewed',
  distanceKm: 2.8,
  jobId: 12,
  title: 'Fuga urgente',
  description: 'Existe una fuga debajo del lavabo.',
  serviceMode: 'immediate',
);
const professionalJob = JobModel(
  id: 12,
  title: 'Reparar lavabo',
  description: 'Existe una fuga debajo del lavabo.',
  status: JobStatus.paid,
  statusLabel: 'Pagado',
);

final class FakeProfessionalAuthRepository implements AuthRepository {
  @override
  Future<AuthSession> loginWithGoogle({required String idToken}) async =>
      professionalSession;

  @override
  Future<void> clearLocalSession() async {}
  @override
  Future<AuthSession> login({
    required String email,
    required String password,
  }) async => professionalSession;
  @override
  Future<void> logout() async {}
  @override
  Future<void> logoutAll() async {}
  @override
  Future<User> me() async => professionalUser;
  @override
  Future<AuthSession> register(RegistrationInput input) async =>
      professionalSession;
  @override
  Future<User?> restoreSession() async => professionalUser;
}

final class FakeProfessionalProfileRepository
    implements ProfessionalProfileRepository {
  ProfessionalProfileModel value = professionalProfile;
  @override
  Future<ProfessionalProfileModel> getProfile() async => value;
  @override
  Future<ProfessionalProfileModel> updateProfile(
    ProfessionalProfileInput input,
  ) async => value;
}

final class FakeAvailabilityRepository implements AvailabilityRepository {
  FakeAvailabilityRepository({this.value = unavailable, this.error});
  AvailabilityModel value;
  Object? error;
  int updateCalls = 0;
  @override
  Future<AvailabilityModel> getAvailability() async => value;
  @override
  Future<AvailabilityModel> updateAvailability({
    required bool isAvailable,
    required int serviceRadiusKm,
    double? latitude,
    double? longitude,
  }) async {
    updateCalls++;
    if (error != null) throw error!;
    value = AvailabilityModel(
      isAvailable: isAvailable,
      availabilityStatus: isAvailable ? 'available' : value.availabilityStatus,
      serviceRadiusKm: serviceRadiusKm,
      latitude: latitude ?? value.latitude,
      longitude: longitude ?? value.longitude,
    );
    return value;
  }
}

final class FakeProfessionalServiceRepository
    implements ProfessionalServiceRepository {
  List<ProfessionalServiceModel> values = [professionalService];
  @override
  Future<ProfessionalServiceModel> create(
    ProfessionalServiceInput input,
  ) async => professionalService;
  @override
  Future<void> delete(int id) async =>
      values.removeWhere((item) => item.id == id);
  @override
  Future<List<ProfessionalServiceModel>> getServices({int page = 1}) async =>
      values;
  @override
  Future<ProfessionalServiceModel> update(
    int id,
    ProfessionalServiceInput input,
  ) async => professionalService;
}

final class FakeInvitationRepository implements JobInvitationRepository {
  List<JobInvitationModel> values = const [invitation];
  List<List<JobInvitationModel>> getResponses = const [];
  int getCalls = 0;
  Object? acceptError;
  Object? declineError;
  int acceptCalls = 0;
  int declineCalls = 0;
  JobModel acceptedJob = professionalJob;
  Completer<JobModel>? acceptCompleter;

  @override
  Future<JobModel> acceptInvitation(int invitationId) async {
    acceptCalls++;
    if (acceptError != null) throw acceptError!;
    if (acceptCompleter != null) return acceptCompleter!.future;
    return acceptedJob;
  }

  @override
  Future<void> declineInvitation(int invitationId) async {
    declineCalls++;
    if (declineError != null) throw declineError!;
  }

  @override
  Future<List<JobInvitationModel>> getInvitations({int page = 1}) async {
    if (getResponses.isNotEmpty) {
      final index = getCalls.clamp(0, getResponses.length - 1);
      getCalls++;
      return getResponses[index];
    }
    getCalls++;
    return values;
  }
}

final class FakeProfessionalJobRepository implements ProfessionalJobRepository {
  List<JobModel> values = const [professionalJob];
  @override
  Future<List<JobModel>> getJobs({JobStatus? status, int page = 1}) async =>
      values;
}

final class FakeLocationService implements LocationService {
  FakeLocationService({
    this.position = const AppPosition(latitude: 20.67, longitude: -103.34),
    this.error,
  });
  final AppPosition position;
  final Object? error;
  @override
  Future<AppPosition> determinePosition() async {
    if (error != null) throw error!;
    return position;
  }

  @override
  Future<void> openSettings() async {}
}
