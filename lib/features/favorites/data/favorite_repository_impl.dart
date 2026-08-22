import 'package:chambapp_mobile/core/errors/api_error_mapper.dart';
import 'package:chambapp_mobile/core/network/json_helpers.dart';
import 'package:chambapp_mobile/features/catalog/domain/catalog_models.dart';
import 'package:chambapp_mobile/features/favorites/domain/favorite_repository.dart';
import 'package:dio/dio.dart';

final class ApiFavoriteRepository implements FavoriteRepository {
  ApiFavoriteRepository(this._dio, this._errors);
  final Dio _dio;
  final ApiErrorMapper _errors;

  @override
  Future<List<ProfessionalModel>> getFavorites() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/favorites');
      return jsonList(response.data?['data'])
          .map(ProfessionalModel.fromJson)
          .toList();
    } catch (error) {
      throw _errors.map(error);
    }
  }

  @override
  Future<void> add(int professionalId) async {
    try {
      await _dio.post<void>('/favorites/$professionalId');
    } catch (error) {
      throw _errors.map(error);
    }
  }

  @override
  Future<void> remove(int professionalId) async {
    try {
      await _dio.delete<void>('/favorites/$professionalId');
    } catch (error) {
      throw _errors.map(error);
    }
  }
}
