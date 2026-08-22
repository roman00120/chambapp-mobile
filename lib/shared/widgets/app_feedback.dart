import 'package:chambapp_mobile/core/theme/app_tokens.dart';
import 'package:flutter/material.dart';

enum FeedbackType { success, error, warning }

final class AppFeedback {
  AppFeedback._();

  static void show(
    BuildContext context,
    String message, {
    FeedbackType type = FeedbackType.error,
  }) {
    final color = switch (type) {
      FeedbackType.success => AppColors.success,
      FeedbackType.error => AppColors.danger,
      FeedbackType.warning => AppColors.amberDark,
    };
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: color,
          behavior: SnackBarBehavior.floating,
        ),
      );
  }
}
