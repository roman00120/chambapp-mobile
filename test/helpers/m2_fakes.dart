import 'dart:async';

import 'package:chambapp_mobile/features/catalog/domain/catalog_models.dart';
import 'package:chambapp_mobile/features/catalog/domain/catalog_repositories.dart';
import 'package:chambapp_mobile/features/favorites/domain/favorite_repository.dart';
import 'package:chambapp_mobile/features/jobs/domain/job_models.dart';
import 'package:chambapp_mobile/features/jobs/domain/job_repository.dart';
import 'package:chambapp_mobile/features/notifications/domain/notification_models.dart';
import 'package:chambapp_mobile/features/notifications/domain/notification_repository.dart';

const testCategory = CategoryModel(id: 1, name: 'Plomería', slug: 'plomeria');
const testProfessional = ProfessionalModel(
  id: 3,
  name: 'Luis Profesional',
  rating: 4.9,
  totalReviews: 12,
  completedJobs: 25,
  verified: true,
  city: 'Guadalajara',
  state: 'Jalisco',
);
const testService = ServiceModel(
  id: 9,
  title: 'Reparación de fugas',
  description: 'Solución profesional para fugas del hogar.',
  priceType: 'quote',
  currency: 'MXN',
  category: testCategory,
  professional: testProfessional,
);
const testJob = JobModel(
  id: 12,
  title: 'Solicitud inmediata',
  description: 'Tengo una fuga debajo del fregadero.',
  status: JobStatus.searching,
  statusLabel: 'Buscando profesional',
  category: testCategory,
);

final class FakeCategoryRepository implements CategoryRepository {
  @override
  Future<List<CategoryModel>> getCategories() async => const [testCategory];
}

final class FakeServiceRepository implements ServiceRepository {
  List<ServiceModel> services = const [testService];

  @override
  Future<ServiceModel> getService(int id) async =>
      services.firstWhere((s) => s.id == id, orElse: () => testService);

  @override
  Future<List<ServiceModel>> search({
    String? query,
    String? categorySlug,
    int page = 1,
  }) async => services;
}

final class FakeProfessionalRepository implements ProfessionalRepository {
  @override
  Future<ProfessionalModel> getProfessional(int id) async => testProfessional;

  @override
  Future<List<ReviewModel>> getReviews(
    int professionalId, {
    int page = 1,
  }) async => const [];
}

final class FakeFavoriteRepository implements FavoriteRepository {
  List<ProfessionalModel> values = const [];

  @override
  Future<void> add(int professionalId) async {}

  @override
  Future<List<ProfessionalModel>> getFavorites() async => values;

  @override
  Future<void> remove(int professionalId) async {}
}

final class FakeJobRepository implements JobRepository {
  FakeJobRepository({List<JobStatusModel>? statuses})
    : statuses =
          statuses ??
          [
            const JobStatusModel(
              status: JobStatus.searching,
              label: 'Buscando profesional',
            ),
          ];

  final List<JobStatusModel> statuses;
  int statusCalls = 0;
  int getJobCalls = 0;
  int immediateCalls = 0;
  Completer<JobModel>? immediateCompleter;
  List<JobModel> jobs = const [testJob];
  JobModel job = testJob;
  JobModel? workflowResult;
  Object? workflowError;
  Completer<JobModel>? workflowCompleter;
  int onTheWayCalls = 0;
  int arrivedCalls = 0;
  int startCalls = 0;
  int finishCalls = 0;
  int confirmCalls = 0;
  int disputeCalls = 0;

  int createScheduledCalls = 0;
  ScheduledJobInput? lastScheduledInput;
  JobModel? scheduledJobResult;
  JobModel? immediateJobResult;

  @override
  Future<JobModel> createImmediate(ImmediateJobInput input) {
    immediateCalls++;
    return immediateCompleter?.future ?? Future.value(immediateJobResult ?? testJob);
  }

  @override
  Future<JobModel> createScheduled(ScheduledJobInput input) async {
    createScheduledCalls++;
    lastScheduledInput = input;
    return scheduledJobResult ?? testJob;
  }

  @override
  Future<JobModel> getJob(int id) async {
    getJobCalls++;
    return job;
  }

  @override
  Future<List<JobModel>> getJobs({JobStatus? status, int page = 1}) async =>
      jobs;

  @override
  Future<JobStatusModel> getStatus(int id) async {
    final index = statusCalls.clamp(0, statuses.length - 1);
    statusCalls++;
    return statuses[index];
  }

  @override
  Future<JobModel> markOnTheWay(int id) {
    onTheWayCalls++;
    return _workflow();
  }

  @override
  Future<JobModel> markArrived(int id) {
    arrivedCalls++;
    return _workflow();
  }

  @override
  Future<JobModel> startJob(int id) {
    startCalls++;
    return _workflow();
  }

  @override
  Future<JobModel> finishJob(int id) {
    finishCalls++;
    return _workflow();
  }

  @override
  Future<JobModel> confirmJob(int id, String completionCode) {
    confirmCalls++;
    return _workflow();
  }

  @override
  Future<JobModel> acceptJob(int id) {
    return _workflow();
  }

  @override
  Future<JobModel> rejectJob(int id) {
    return _workflow();
  }

  @override
  Future<JobModel> reportProblem(
    int id, {
    required DisputeReason reason,
    String? description,
  }) {
    disputeCalls++;
    return _workflow();
  }

  Future<JobModel> _workflow() {
    if (workflowError != null) return Future.error(workflowError!);
    return workflowCompleter?.future ?? Future.value(workflowResult ?? job);
  }
}

final class FakeNotificationRepository implements NotificationRepository {
  @override
  Future<NotificationPage> getNotifications({int page = 1}) async =>
      const NotificationPage(items: [], unreadCount: 0);

  @override
  Future<void> markAllRead() async {}

  @override
  Future<AppNotification> markRead(String id) => throw UnimplementedError();
}
