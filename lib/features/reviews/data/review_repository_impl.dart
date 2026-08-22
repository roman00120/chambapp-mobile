import 'package:chambapp_mobile/core/errors/api_error_mapper.dart';
import 'package:chambapp_mobile/core/network/json_helpers.dart';
import 'package:chambapp_mobile/features/catalog/domain/catalog_models.dart';
import 'package:chambapp_mobile/features/reviews/domain/review_repository.dart';
import 'package:dio/dio.dart';

final class ApiReviewRepository implements ReviewRepository {
  ApiReviewRepository(this._dio, this._errors);
  final Dio _dio;
  final ApiErrorMapper _errors;

  @override
  Future<ReviewModel> create(
    int jobId, {
    required int rating,
    String? comment,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/jobs/$jobId/review',
        data: {
          'rating': rating,
          if (comment?.trim().isNotEmpty == true) 'comment': comment!.trim(),
        },
      );
      return ReviewModel.fromJson(jsonMap(response.data?['data']));
    } catch (error) {
      throw _errors.map(error);
    }
  }
}
