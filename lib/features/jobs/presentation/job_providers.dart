import 'package:chambapp_mobile/app/providers.dart';
import 'package:chambapp_mobile/core/errors/api_error_mapper.dart';
import 'package:chambapp_mobile/features/jobs/data/job_repository_impl.dart';
import 'package:chambapp_mobile/features/jobs/data/commerce_repositories_impl.dart';
import 'package:chambapp_mobile/features/jobs/domain/commerce_repositories.dart';
import 'package:chambapp_mobile/features/jobs/domain/job_models.dart';
import 'package:chambapp_mobile/features/jobs/domain/job_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final jobRepositoryProvider = Provider<JobRepository>(
  (ref) => ApiJobRepository(ref.watch(dioProvider), const ApiErrorMapper()),
);
final quoteRepositoryProvider = Provider<QuoteRepository>(
  (ref) => ApiQuoteRepository(ref.watch(dioProvider), const ApiErrorMapper()),
);
final paymentRepositoryProvider = Provider<PaymentRepository>(
  (ref) => ApiPaymentRepository(ref.watch(dioProvider), const ApiErrorMapper()),
);

final jobsProvider = FutureProvider.family<List<JobModel>, JobStatus?>((
  ref,
  status,
) {
  final userId = ref.watch(
    authControllerProvider.select((state) => state.user?.id),
  );
  if (userId == null) return Future.value(const []);
  return ref.watch(jobRepositoryProvider).getJobs(status: status);
});
final jobDetailProvider = FutureProvider.family<JobModel, int>((ref, id) {
  ref.watch(authControllerProvider.select((state) => state.user?.id));
  return ref.watch(jobRepositoryProvider).getJob(id);
});
final jobQuotesProvider = FutureProvider.family<List<JobQuoteModel>, int>((
  ref,
  id,
) {
  ref.watch(authControllerProvider.select((state) => state.user?.id));
  return ref.watch(quoteRepositoryProvider).getQuotes(id);
});
