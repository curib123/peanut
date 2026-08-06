import 'package:flutter/material.dart';

import 'app_colors.dart';

abstract final class AppTheme {
  static ThemeData get light {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.gold,
      brightness: Brightness.light,
      primary: AppColors.caramel,
      secondary: AppColors.palm,
      surface: AppColors.coconut,
    );

    return ThemeData(
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.cream,
      useMaterial3: true,
      textTheme: const TextTheme(
        displaySmall: TextStyle(
          color: AppColors.cocoa,
          fontWeight: FontWeight.w900,
          height: 1,
        ),
        titleLarge: TextStyle(
          color: AppColors.cocoa,
          fontWeight: FontWeight.w800,
        ),
        bodyLarge: TextStyle(color: AppColors.cocoa),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.gold,
          foregroundColor: AppColors.cocoa,
          minimumSize: const Size(220, 56),
          textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
    );
  }
}
