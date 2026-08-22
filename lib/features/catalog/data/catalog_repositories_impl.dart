import 'package:chambapp_mobile/core/errors/api_error_mapper.dart';
import 'package:chambapp_mobile/core/network/json_helpers.dart';
import 'package:chambapp_mobile/features/catalog/domain/catalog_models.dart';
import 'package:chambapp_mobile/features/catalog/domain/catalog_repositories.dart';
import 'package:dio/dio.dart';

final class ApiCategoryRepository implements CategoryRepository {
  ApiCategoryRepository(this._dio, this._errors);
  final Dio _dio;
  final ApiErrorMapper _errors;

  @override
  Future<List<CategoryModel>> getCategories() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/categories');
      return jsonList(response.data?['data'])
          .map(CategoryModel.fromJson)
          .toList();
    } catch (error) {
      throw _errors.map(error);
    }
  }
}

final class ApiServiceRepository implements ServiceRepository {
  ApiServiceRepository(this._dio, this._errors);
  final Dio _dio;
  final ApiErrorMapper _errors;

  @override
  Future<List<ServiceModel>> search({
    String? query,
    String? categorySlug,
    int page = 1,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/services',
        queryParameters: {
          if (query?.trim().isNotEmpty == true) 'q': query!.trim(),
          if (categorySlug?.isNotEmpty == true) 'category': categorySlug,
          'page': page,
        },
      );
      return jsonList(response.data?['data'])
          .map(ServiceModel.fromJson)
          .toList();
    } catch (error) {
      throw _errors.map(error);
    }
  }

  @override
  Future<ServiceModel> getService(int id) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/services/$id');
      return ServiceModel.fromJson(jsonMap(response.data?['data']));
    } catch (error) {
      throw _errors.map(error);
    }
  }
}

final class ApiProfessionalRepository implements ProfessionalRepository {
  ApiProfessionalRepository(this._dio, this._errors);
  final Dio _dio;
  final ApiErrorMapper _errors;

  @override
  Future<ProfessionalModel> getProfessional(int id) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/professionals/$id',
      );
      return ProfessionalModel.fromJson(jsonMap(response.data?['data']));
    } catch (error) {
      throw _errors.map(error);
    }
  }

  @override
  Future<List<ReviewModel>> getReviews(
    int professionalId, {
    int page = 1,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/professionals/$professionalId/reviews',
        queryParameters: {'page': page},
      );
      return jsonList(response.data?['data'])
          .map(ReviewModel.fromJson)
          .toList();
    } catch (error) {
      throw _errors.map(error);
    }
  }
}
