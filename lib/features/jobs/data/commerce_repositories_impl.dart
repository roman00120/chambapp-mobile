import 'package:chambapp_mobile/core/errors/api_error_mapper.dart';
import 'package:chambapp_mobile/core/network/json_helpers.dart';
import 'package:chambapp_mobile/features/jobs/domain/commerce_repositories.dart';
import 'package:chambapp_mobile/features/jobs/domain/job_models.dart';
import 'package:dio/dio.dart';

final class ApiQuoteRepository implements QuoteRepository {
  ApiQuoteRepository(this._dio, this._errors);
  final Dio _dio;
  final ApiErrorMapper _errors;

  @override
  Future<List<JobQuoteModel>> getQuotes(int jobId, {int page = 1}) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/jobs/$jobId/quotes',
        queryParameters: {'page': page},
      );
      return jsonList(response.data?['data'])
          .map(JobQuoteModel.fromJson)
          .toList();
    } catch (error) {
      throw _errors.map(error);
    }
  }

  @override
  Future<JobQuoteModel> createQuote(
    int jobId, {
    required String amount,
    required String description,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/professional/jobs/$jobId/quotes',
        data: {'amount': amount, 'description': description.trim()},
      );
      return JobQuoteModel.fromJson(jsonMap(response.data?['data']));
    } catch (error) {
      throw _errors.map(error);
    }
  }

  @override
  Future<JobQuoteModel> acceptQuote(int jobId, int quoteId) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/jobs/$jobId/quotes/$quoteId/accept',
      );
      return JobQuoteModel.fromJson(jsonMap(response.data?['data']));
    } catch (error) {
      throw _errors.map(error);
    }
  }

  @override
  Future<JobQuoteModel> rejectQuote(
    int jobId,
    int quoteId, {
    required String reason,
    String? reasonDetail,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/jobs/$jobId/quotes/$quoteId/reject',
        data: {
          'reason': reason,
          if (reasonDetail?.trim().isNotEmpty == true)
            'reason_detail': reasonDetail!.trim(),
        },
      );
      return JobQuoteModel.fromJson(jsonMap(response.data?['data']));
    } catch (error) {
      throw _errors.map(error);
    }
  }
}

final class ApiPaymentRepository implements PaymentRepository {
  ApiPaymentRepository(this._dio, this._errors);
  final Dio _dio;
  final ApiErrorMapper _errors;

  @override
  Future<CheckoutResult> createCheckout(int jobId) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/jobs/$jobId/checkout',
      );
      final data = jsonMap(response.data?['data']);
      return CheckoutResult(
        checkoutUrl: data['checkout_url']?.toString() ?? '',
        payment: PaymentModel.fromJson(jsonMap(data['payment'])),
      );
    } catch (error) {
      throw _errors.map(error);
    }
  }

  @override
  Future<PaymentModel> getPayment(int paymentId) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/payments/$paymentId',
      );
      return PaymentModel.fromJson(jsonMap(response.data?['data']));
    } catch (error) {
      throw _errors.map(error);
    }
  }
}
