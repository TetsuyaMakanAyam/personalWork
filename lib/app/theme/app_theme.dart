import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_typography.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get darkTheme {
    final textTheme = AppTypography.buildTextTheme(isDark: true);
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.darkBackground,
      primaryColor: AppColors.primaryAccent,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primaryAccent,
        secondary: AppColors.secondaryAccent,
        surface: AppColors.darkSecondarySurface,
        error: AppColors.criticalDanger,
        onPrimary: AppColors.darkBackground,
        onSecondary: AppColors.darkMainText,
        onSurface: AppColors.darkMainText,
      ),
      textTheme: textTheme,
      cardColor: AppColors.darkElevatedCard,
      dividerColor: AppColors.darkGlassBorder,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.headlineMedium,
        iconTheme: const IconThemeData(color: AppColors.darkMainText),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.darkElevatedCard,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: AppColors.darkMainText,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: AppColors.darkGlassBorder),
        ),
        behavior: SnackBarBehavior.floating,
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: AppColors.primaryAccent,
        inactiveTrackColor: AppColors.darkBackground,
        thumbColor: AppColors.primaryAccent,
        overlayColor: AppColors.primaryAccent.withOpacity(0.18),
        trackHeight: 6,
      ),
    );
  }

  static ThemeData get lightTheme {
    final textTheme = AppTypography.buildTextTheme(isDark: false);
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.lightBackground,
      primaryColor: const Color(0xFF0284C7),
      colorScheme: const ColorScheme.light(
        primary: Color(0xFF0284C7),
        secondary: AppColors.secondaryAccent,
        surface: AppColors.lightSecondarySurface,
        error: AppColors.criticalDanger,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: AppColors.lightMainText,
      ),
      textTheme: textTheme,
      cardColor: AppColors.lightElevatedCard,
      dividerColor: AppColors.lightGlassBorder,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.headlineMedium,
        iconTheme: const IconThemeData(color: AppColors.lightMainText),
      ),
    );
  }
}
