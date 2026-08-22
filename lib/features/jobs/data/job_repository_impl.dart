import 'package:chambapp_mobile/core/errors/api_error_mapper.dart';
import 'package:chambapp_mobile/core/network/json_helpers.dart';
import 'package:chambapp_mobile/features/jobs/domain/job_models.dart';
import 'package:chambapp_mobile/features/jobs/domain/job_repository.dart';
import 'package:dio/dio.dart';

final class ApiJobRepository implements JobRepository {
  ApiJobRepository(this._dio, this._errors);
  final Dio _dio;
  final ApiErrorMapper _errors;

  @override
  Future<List<JobModel>> getJobs({JobStatus? status, int page = 1}) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/jobs',
        queryParameters: {
          if (status != null && status != JobStatus.unknown)
            'status': status.apiValue,
          'page': page,
        },
      );
      return jsonList(response.data?['data']).map(JobModel.fromJson).toList();
    } catch (error) {
      throw _errors.map(error);
    }
  }

  @override
  Future<JobModel> getJob(int id) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/jobs/$id');
      return JobModel.fromJson(jsonMap(response.data?['data']));
    } catch (error) {
      throw _errors.map(error);
    }
  }

  @override
  Future<JobModel> createImmediate(ImmediateJobInput input) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/jobs/immediate',
        data: FormData.fromMap({
          'category_id': input.categoryId,
          if (input.serviceId != null) 'service_id': input.serviceId,
          'description': input.description.trim(),
          ...input.location.toJson(),
        }),
      );
      return JobModel.fromJson(jsonMap(response.data?['data']));
    } catch (error) {
      throw _errors.map(error);
    }
  }

  @override
  Future<JobModel> createScheduled(ScheduledJobInput input) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/jobs/scheduled',
        data: {
          'service_mode': 'scheduled',
          'category_id': input.categoryId,
          if (input.serviceId != null) 'service_id': input.serviceId,
          'title': input.title.trim(),
          'description': input.description.trim(),
          'scheduled_for': input.scheduledFor.toIso8601String(),
          'scheduled_slot': input.scheduledSlot,
          ...input.location.toJson(),
        },
      );
      return JobModel.fromJson(jsonMap(response.data?['data']));
    } catch (error) {
      throw _errors.map(error);
    }
  }

  @override
  Future<JobStatusModel> getStatus(int id) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/jobs/$id/status');
      return JobStatusModel.fromJson(jsonMap(response.data?['data']));
    } catch (error) {
      throw _errors.map(error);
    }
  }

  @override
  Future<JobModel> markOnTheWay(int id) => _workflow('/jobs/$id/on-the-way');

  @override
  Future<JobModel> markArrived(int id) => _workflow('/jobs/$id/arrived');

  @override
  Future<JobModel> startJob(int id) => _workflow('/jobs/$id/start');

  @override
  Future<JobModel> finishJob(int id) => _workflow('/jobs/$id/finish');

  @override
  Future<JobModel> confirmJob(int id, String completionCode) =>
      _workflow('/jobs/$id/confirm', data: {'completion_code': completionCode});

  @override
  Future<JobModel> reportProblem(
    int id, {
    required DisputeReason reason,
    String? description,
  }) => _workflow(
    '/jobs/$id/dispute',
    data: {
      'reason': reason.apiValue,
      if (description?.trim().isNotEmpty == true)
        'description': description!.trim(),
    },
  );

  Future<JobModel> _workflow(String path, {Map<String, dynamic>? data}) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(path, data: data);
      return JobModel.fromJson(jsonMap(response.data?['data']));
    } catch (error) {
      throw _errors.map(error);
    }
  }
}
