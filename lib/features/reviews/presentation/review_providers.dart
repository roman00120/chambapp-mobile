import 'package:chambapp_mobile/app/providers.dart';
import 'package:chambapp_mobile/core/errors/api_error_mapper.dart';
import 'package:chambapp_mobile/features/catalog/domain/catalog_models.dart';
import 'package:chambapp_mobile/features/catalog/presentation/catalog_providers.dart';
import 'package:chambapp_mobile/features/reviews/data/review_repository_impl.dart';
import 'package:chambapp_mobile/features/reviews/domain/review_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final reviewRepositoryProvider = Provider<ReviewRepository>(
  (ref) => ApiReviewRepository(ref.watch(dioProvider), const ApiErrorMapper()),
);

final professionalReviewsProvider =
    FutureProvider.family<List<ReviewModel>, int>(
      (ref, professionalId) =>
          ref.watch(professionalRepositoryProvider).getReviews(professionalId),
    );
