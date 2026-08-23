import 'package:chambapp_mobile/core/errors/api_error_mapper.dart';
import 'package:chambapp_mobile/core/network/json_helpers.dart';
import 'package:chambapp_mobile/features/jobs/domain/job_models.dart';
import 'package:chambapp_mobile/features/professional/domain/professional_models.dart';
import 'package:chambapp_mobile/features/professional/domain/professional_repositories.dart';
import 'package:dio/dio.dart';

final class ApiProfessionalProfileRepository
    implements ProfessionalProfileRepository {
  ApiProfessionalProfileRepository(this._dio, this._errors);
  final Dio _dio;
  final ApiErrorMapper _errors;

  @override
  Future<ProfessionalProfileModel> getProfile() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/professional/profile',
      );
      return ProfessionalProfileModel.fromJson(jsonMap(response.data?['data']));
    } catch (error) {
      throw _errors.map(error);
    }
  }

  @override
  Future<ProfessionalProfileModel> updateProfile(
    ProfessionalProfileInput input,
  ) async {
    try {
      final baseData = <String, dynamic>{
        'name': input.name.trim(),
        'phone': input.phone.trim(),
        'experience_years': input.experienceYears,
        'bio': input.bio?.trim() ?? '',
        'city': input.city?.trim() ?? '',
        'state': input.state?.trim() ?? '',
        'postal_code': input.postalCode?.trim() ?? '',
      };
      if (input.photoPath != null) {
        final formMap = Map<String, dynamic>.from(baseData)
          ..['_method'] = 'PATCH'
          ..['profile_photo'] = await MultipartFile.fromFile(
            input.photoPath!,
            filename: input.photoPath!.split(RegExp(r'[/\\]')).last,
          );
        final response = await _dio.post<Map<String, dynamic>>(
          '/professional/profile',
          data: FormData.fromMap(formMap),
        );
        return ProfessionalProfileModel.fromJson(
          jsonMap(response.data?['data']),
        );
      }
      final response = await _dio.patch<Map<String, dynamic>>(
        '/professional/profile',
        data: baseData,
      );
      return ProfessionalProfileModel.fromJson(jsonMap(response.data?['data']));
    } catch (error) {
      throw _errors.map(error);
    }
  }
}

final class ApiAvailabilityRepository implements AvailabilityRepository {
  ApiAvailabilityRepository(this._dio, this._errors);
  final Dio _dio;
  final ApiErrorMapper _errors;

  @override
  Future<AvailabilityModel> getAvailability() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/professional/availability',
      );
      return AvailabilityModel.fromJson(jsonMap(response.data?['data']));
    } catch (error) {
      throw _errors.map(error);
    }
  }

  @override
  Future<AvailabilityModel> updateAvailability({
    required bool isAvailable,
    required int serviceRadiusKm,
    double? latitude,
    double? longitude,
  }) async {
    try {
      final response = await _dio.put<Map<String, dynamic>>(
        '/professional/availability',
        data: {
          'is_available': isAvailable,
          'service_radius_km': serviceRadiusKm,
          'latitude': ?latitude,
          'longitude': ?longitude,
        },
      );
      return AvailabilityModel.fromJson(jsonMap(response.data?['data']));
    } catch (error) {
      throw _errors.map(error);
    }
  }
}

final class ApiProfessionalServiceRepository
    implements ProfessionalServiceRepository {
  ApiProfessionalServiceRepository(this._dio, this._errors);
  final Dio _dio;
  final ApiErrorMapper _errors;

  @override
  Future<List<ProfessionalServiceModel>> getServices({int page = 1}) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/professional/services',
        queryParameters: {'page': page},
      );
      return jsonList(response.data?['data'])
          .map(ProfessionalServiceModel.fromJson)
          .toList();
    } catch (error) {
      throw _errors.map(error);
    }
  }

  @override
  Future<ProfessionalServiceModel> create(ProfessionalServiceInput input) =>
      _save('/professional/services', input, create: true);

  @override
  Future<ProfessionalServiceModel> update(
    int id,
    ProfessionalServiceInput input,
  ) => _save('/professional/services/$id', input, create: false);

  Future<ProfessionalServiceModel> _save(
    String path,
    ProfessionalServiceInput input, {
    required bool create,
  }) async {
    try {
      final files = <MultipartFile>[];
      for (final imagePath in input.imagePaths) {
        files.add(
          await MultipartFile.fromFile(
            imagePath,
            filename: imagePath.split(RegExp(r'[/\\]')).last,
          ),
        );
      }
      if (create) {
        final form = FormData.fromMap({
          'category_id': input.categoryId,
          'title': input.title.trim(),
          'description': input.description.trim(),
          'price_type': input.priceType.apiValue,
          if (input.priceType != ProfessionalPriceType.quote)
            'price': input.price?.trim(),
          if (files.isNotEmpty) 'images': files,
        }, ListFormat.multiCompatible);
        final response = await _dio.post<Map<String, dynamic>>(
          path,
          data: form,
        );
        return ProfessionalServiceModel.fromJson(
          jsonMap(response.data?['data']),
        );
      }
      if (files.isNotEmpty) {
        final form = FormData.fromMap({
          '_method': 'PATCH',
          'category_id': input.categoryId,
          'title': input.title.trim(),
          'description': input.description.trim(),
          'price_type': input.priceType.apiValue,
          if (input.priceType != ProfessionalPriceType.quote)
            'price': input.price?.trim(),
          'images': files,
        }, ListFormat.multiCompatible);
        final response = await _dio.post<Map<String, dynamic>>(
          path,
          data: form,
        );
        return ProfessionalServiceModel.fromJson(
          jsonMap(response.data?['data']),
        );
      }
      final response = await _dio.patch<Map<String, dynamic>>(
        path,
        data: {
          'category_id': input.categoryId,
          'title': input.title.trim(),
          'description': input.description.trim(),
          'price_type': input.priceType.apiValue,
          if (input.priceType != ProfessionalPriceType.quote)
            'price': input.price?.trim(),
        },
      );
      return ProfessionalServiceModel.fromJson(jsonMap(response.data?['data']));
    } catch (error) {
      throw _errors.map(error);
    }
  }

  @override
  Future<void> delete(int id) async {
    try {
      await _dio.delete<void>('/professional/services/$id');
    } catch (error) {
      throw _errors.map(error);
    }
  }
}

final class ApiJobInvitationRepository implements JobInvitationRepository {
  ApiJobInvitationRepository(this._dio, this._errors);
  final Dio _dio;
  final ApiErrorMapper _errors;

  @override
  Future<List<JobInvitationModel>> getInvitations({int page = 1}) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/professional/job-invitations',
        queryParameters: {'page': page},
      );
      return jsonList(response.data?['data'])
          .map(JobInvitationModel.fromJson)
          .where((item) => !item.expired)
          .toList();
    } catch (error) {
      throw _errors.map(error);
    }
  }

  @override
  Future<JobModel> acceptInvitation(int invitationId) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/professional/job-invitations/$invitationId/accept',
      );
      return JobModel.fromJson(jsonMap(response.data?['data']));
    } catch (error) {
      throw _errors.map(error);
    }
  }

  @override
  Future<void> declineInvitation(int invitationId) async {
    try {
      await _dio.post<void>(
        '/professional/job-invitations/$invitationId/decline',
      );
    } catch (error) {
      throw _errors.map(error);
    }
  }
}

final class ApiProfessionalJobRepository implements ProfessionalJobRepository {
  ApiProfessionalJobRepository(this._dio, this._errors);
  final Dio _dio;
  final ApiErrorMapper _errors;

  @override
  Future<List<JobModel>> getJobs({JobStatus? status, int page = 1}) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/professional/jobs',
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
}
