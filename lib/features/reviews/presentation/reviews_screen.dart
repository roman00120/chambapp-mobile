import 'package:chambapp_mobile/core/theme/app_tokens.dart';
import 'package:chambapp_mobile/features/catalog/domain/catalog_models.dart';
import 'package:chambapp_mobile/features/reviews/presentation/review_providers.dart';
import 'package:chambapp_mobile/shared/widgets/error_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ReviewsScreen extends ConsumerWidget {
  const ReviewsScreen({required this.professionalId, super.key});
  final int professionalId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reviews = ref.watch(professionalReviewsProvider(professionalId));
    return Scaffold(
      appBar: AppBar(title: const Text('Reseñas')),
      body: reviews.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => ErrorState(
          title: 'No pudimos cargar las reseñas',
          message: error,
          onRetry: () =>
              ref.invalidate(professionalReviewsProvider(professionalId)),
        ),
        data: (items) => items.isEmpty
            ? const Center(child: Text('Aún no hay reseñas.'))
            : RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(professionalReviewsProvider(professionalId));
                  await ref.read(
                    professionalReviewsProvider(professionalId).future,
                  );
                },
                child: ListView.separated(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  itemCount: items.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (_, index) => ReviewCard(review: items[index]),
                ),
              ),
      ),
    );
  }
}

class ReviewCard extends StatelessWidget {
  const ReviewCard({required this.review, super.key});
  final ReviewModel review;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  review.clientName,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              Semantics(
                label: '${review.rating} de 5 estrellas',
                child: Text('${'★' * review.rating} ${review.rating}/5'),
              ),
            ],
          ),
          if (review.comment?.isNotEmpty == true) Text(review.comment!),
          if (review.createdAt != null)
            Text(
              '${review.createdAt!.toLocal().day}/${review.createdAt!.toLocal().month}/${review.createdAt!.toLocal().year}',
            ),
        ],
      ),
    ),
  );
}
