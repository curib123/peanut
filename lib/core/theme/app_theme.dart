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
      fontFamily: 'Roboto',
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.cream,
      useMaterial3: true,
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        backgroundColor: AppColors.coconut,
        foregroundColor: AppColors.cocoa,
        elevation: 0,
        titleTextStyle: TextStyle(
          fontFamily: 'Roboto',
          color: AppColors.cocoa,
          fontSize: 22,
          fontWeight: FontWeight.w900,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.coconut.withValues(alpha: .96),
        elevation: 10,
        shadowColor: const Color(0x55000000),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
          side: const BorderSide(color: Color(0xFFFFD66B), width: 2),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.coconut,
        elevation: 16,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? Colors.white
              : const Color(0xFFFFE4A0),
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.caramel
              : const Color(0xFFB6A99C),
        ),
      ),
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
