import 'package:chambapp_mobile/core/errors/app_exception.dart';
import 'package:chambapp_mobile/core/theme/app_tokens.dart';
import 'package:chambapp_mobile/features/catalog/domain/catalog_models.dart';
import 'package:chambapp_mobile/features/catalog/presentation/catalog_providers.dart';
import 'package:chambapp_mobile/features/jobs/presentation/job_providers.dart';
import 'package:chambapp_mobile/features/reviews/presentation/review_providers.dart';
import 'package:chambapp_mobile/features/reviews/presentation/star_rating_input.dart';
import 'package:chambapp_mobile/shared/widgets/app_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ReviewFormScreen extends ConsumerStatefulWidget {
  const ReviewFormScreen({
    required this.jobId,
    required this.professionalId,
    super.key,
  });
  final int jobId;
  final int professionalId;

  @override
  ConsumerState<ReviewFormScreen> createState() => _ReviewFormScreenState();
}

class _ReviewFormScreenState extends ConsumerState<ReviewFormScreen> {
  final _comment = TextEditingController();
  int _rating = 0;
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Calificar profesional')),
    body: SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Text(
            '¿Cómo fue tu experiencia?',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: AppSpacing.lg),
          StarRatingInput(
            value: _rating,
            onChanged: _submitting
                ? null
                : (value) => setState(() {
                    _rating = value;
                    _error = null;
                  }),
          ),
          Text(
            ratingLabel(_rating),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.lg),
          AppTextField(
            controller: _comment,
            label: 'Comentario (opcional)',
            maxLines: 5,
            maxLength: 1000,
            enabled: !_submitting,
          ),
          if (_error != null)
            Text(_error!, style: const TextStyle(color: AppColors.danger)),
          const SizedBox(height: AppSpacing.lg),
          FilledButton(
            onPressed: _submitting ? null : _submit,
            child: Text(_submitting ? 'Publicando reseña…' : 'Publicar reseña'),
          ),
        ],
      ),
    ),
  );

  Future<void> _submit() async {
    if (_submitting) return;
    if (_rating < 1 || _rating > 5) {
      setState(() => _error = 'Selecciona una calificación de 1 a 5.');
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final review = await ref
          .read(reviewRepositoryProvider)
          .create(widget.jobId, rating: _rating, comment: _comment.text);
      ref.invalidate(jobDetailProvider(widget.jobId));
      ref.invalidate(jobsProvider(null));
      ref.invalidate(professionalDetailProvider(widget.professionalId));
      ref.invalidate(professionalReviewsProvider(widget.professionalId));
      if (mounted) Navigator.pop<ReviewModel>(context, review);
    } on AppException catch (error) {
      if (!mounted) return;
      setState(() {
        _error =
            error.fieldErrors['comment'] ??
            switch (error.code) {
              'REVIEW_UNAVAILABLE' when error.message.contains('ya tiene') =>
                'Ya calificaste esta chamba.',
              'REVIEW_UNAVAILABLE' =>
                'Solo puedes calificar una chamba completada.',
              _ => error.message,
            };
      });
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }
}
