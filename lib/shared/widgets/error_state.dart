import 'package:chambapp_mobile/core/theme/app_tokens.dart';
import 'package:chambapp_mobile/core/errors/app_exception.dart';
import 'package:chambapp_mobile/shared/widgets/primary_button.dart';
import 'package:flutter/material.dart';

class ErrorState extends StatelessWidget {
  const ErrorState({
    required this.title,
    required this.message,
    required this.onRetry,
    super.key,
  });

  final String title;
  final Object message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.cloud_off_outlined,
            size: 56,
            color: AppColors.muted,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(_safeMessage(message), textAlign: TextAlign.center),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            width: 220,
            child: PrimaryButton(label: 'Reintentar', onPressed: onRetry),
          ),
        ],
      ),
    ),
  );
}

String _safeMessage(Object error) => error is AppException
    ? error.message
    : error is String && !_looksTechnical(error)
    ? error
    : 'No pudimos completar la solicitud. Intenta nuevamente.';

bool _looksTechnical(String value) {
  final lower = value.toLowerCase();
  return lower.contains('dioexception') ||
      lower.contains('stack trace') ||
      lower.contains('socketexception') ||
      lower.contains('http://') ||
      lower.contains('https://');
}
