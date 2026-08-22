import 'package:chambapp_mobile/features/jobs/domain/job_models.dart';

abstract interface class QuoteRepository {
  Future<List<JobQuoteModel>> getQuotes(int jobId, {int page = 1});
  Future<JobQuoteModel> createQuote(
    int jobId, {
    required String amount,
    required String description,
  });
  Future<JobQuoteModel> acceptQuote(int jobId, int quoteId);
  Future<JobQuoteModel> rejectQuote(
    int jobId,
    int quoteId, {
    required String reason,
    String? reasonDetail,
  });
}

abstract interface class PaymentRepository {
  Future<CheckoutResult> createCheckout(int jobId);
  Future<PaymentModel> getPayment(int paymentId);
}
