import 'package:flutter/material.dart';

/// Palette "rosso metallizzato" dell'app.
class AppColors {
  static const background = Color(0xFF0B0507);
  static const surface = Color(0xFF1A0D10);
  static const redDark = Color(0xFF4A0A12);
  static const red = Color(0xFFB3121F);
  static const redBright = Color(0xFFE5303D);
  static const highlight = Color(0xFFFF8A92);
  static const steel = Color(0xFFC9CDD2);
}

class AppTheme {
  /// Gradiente che simula una lamiera rossa lucida.
  static const metalRed = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      AppColors.redBright,
      AppColors.red,
      AppColors.redDark,
      AppColors.red,
    ],
    stops: [0.0, 0.35, 0.7, 1.0],
  );

  static ThemeData get dark {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.red,
      brightness: Brightness.dark,
    ).copyWith(
      surface: AppColors.surface,
      primary: AppColors.redBright,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.background,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        foregroundColor: AppColors.steel,
      ),
    );
  }
}
