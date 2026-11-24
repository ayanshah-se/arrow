import 'package:flutter/material.dart';

import 'app_colors.dart';

abstract final class AppTheme {
  static final light = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: AppColors.background,
    colorScheme: const ColorScheme.light(
      primary: AppColors.accent,
      surface: AppColors.surface,
      onSurface: AppColors.text,
      error: AppColors.danger,
    ),
    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        fontWeight: FontWeight.w900,
        letterSpacing: -0.5,
        color: AppColors.text,
      ),
      titleLarge: TextStyle(
        fontWeight: FontWeight.w800,
        color: AppColors.text,
      ),
      bodyMedium: TextStyle(color: AppColors.textMuted, height: 1.4),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.accent,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
        textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
      ),
    ),
  );
}
