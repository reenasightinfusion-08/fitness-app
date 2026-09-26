import 'package:flutter/material.dart';

import 'package:google_fonts/google_fonts.dart';

import 'package:fitness_app/core/theme/app_colors.dart';

class AppTheme {
  const AppTheme._();

  static ThemeData get light => build(AppColors.light, Brightness.light);
  static ThemeData get dark => build(AppColors.dark, Brightness.dark);

  static ThemeData build(AppColors colors, Brightness brightness) {
    final scheme =
        ColorScheme.fromSeed(
          seedColor: colors.accent,
          brightness: brightness,
        ).copyWith(
          primary: colors.accent,
          onPrimary: colors.accentInk,
          secondary: colors.warm,
          error: colors.danger,
          surface: colors.surface,
          onSurface: colors.ink,
          outline: colors.line,
        );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: colors.ground,
      textTheme: GoogleFonts.figtreeTextTheme().apply(
        bodyColor: colors.ink,
        displayColor: colors.ink,
      ),
      dividerColor: colors.line,
      splashFactory: InkSparkle.splashFactory,
      extensions: [colors],
    );
  }
}

class AppShadows {
  const AppShadows._();

  static List<BoxShadow> soft(AppColors colors) => [
    BoxShadow(
      color: colors.shadow.withValues(alpha: 0.35),
      blurRadius: 2,
      offset: const Offset(0, 1),
    ),
    BoxShadow(
      color: colors.shadow,
      blurRadius: 40,
      offset: const Offset(0, 12),
    ),
  ];

  static List<BoxShadow> lifted(AppColors colors) => [
    BoxShadow(color: colors.shadow, blurRadius: 3, offset: const Offset(0, 1)),
  ];
}
