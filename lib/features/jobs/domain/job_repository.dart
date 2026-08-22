import 'package:chambapp_mobile/features/jobs/domain/job_models.dart';

abstract interface class JobRepository {
  Future<List<JobModel>> getJobs({JobStatus? status, int page = 1});
  Future<JobModel> getJob(int id);
  Future<JobModel> createImmediate(ImmediateJobInput input);
  Future<JobModel> createScheduled(ScheduledJobInput input);
  Future<JobStatusModel> getStatus(int id);
  Future<JobModel> markOnTheWay(int id);
  Future<JobModel> markArrived(int id);
  Future<JobModel> startJob(int id);
  Future<JobModel> finishJob(int id);
  Future<JobModel> confirmJob(int id, String completionCode);
  Future<JobModel> reportProblem(
    int id, {
    required DisputeReason reason,
    String? description,
  });
}
