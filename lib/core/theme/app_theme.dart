import 'package:chambapp_mobile/core/theme/app_tokens.dart';
import 'package:flutter/material.dart';

final class AppTheme {
  AppTheme._();

  static ThemeData get light {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.navy,
      brightness: Brightness.light,
      primary: AppColors.navy,
      secondary: AppColors.amber,
      surface: AppColors.surface,
      error: AppColors.danger,
    );
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadii.input),
      borderSide: const BorderSide(color: Color(0xFFD7E0E8)),
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.canvas,
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontWeight: FontWeight.w800,
          color: AppColors.navy,
        ),
        headlineMedium: TextStyle(
          fontWeight: FontWeight.w800,
          color: AppColors.navy,
        ),
        titleLarge: TextStyle(
          fontWeight: FontWeight.w700,
          color: AppColors.text,
        ),
        bodyLarge: TextStyle(fontSize: 16, height: 1.45, color: AppColors.text),
        bodyMedium: TextStyle(
          fontSize: 14,
          height: 1.4,
          color: AppColors.muted,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: border,
        enabledBorder: border,
        focusedBorder: border.copyWith(
          borderSide: const BorderSide(color: AppColors.navy, width: 2),
        ),
        errorMaxLines: 3,
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.card),
          side: const BorderSide(color: Color(0xFFE4EAF0)),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          backgroundColor: AppColors.amber,
          foregroundColor: AppColors.navy,
          disabledBackgroundColor: AppColors.amber.withValues(alpha: .55),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.button),
          ),
        ),
      ),
    );
  }
}
