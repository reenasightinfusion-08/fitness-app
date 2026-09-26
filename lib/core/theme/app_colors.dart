import 'package:flutter/material.dart';

/// Loosen palette. The only file allowed to hold raw color values.
///
/// Registered as a [ThemeExtension] so every token flips automatically
/// between light and dark mode. Read it with `context.colors`.
@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.ground,
    required this.surface,
    required this.surface2,
    required this.ink,
    required this.ink2,
    required this.ink3,
    required this.line,
    required this.accent,
    required this.accentInk,
    required this.accentSoft,
    required this.warm,
    required this.warmSoft,
    required this.danger,
    required this.dangerSoft,
    required this.playerBg,
    required this.playerInk,
    required this.playerDim,
    required this.figFar,
    required this.scrim,
    required this.shadow,
  });

  final Color ground;
  final Color surface;
  final Color surface2;
  final Color ink;
  final Color ink2;
  final Color ink3;
  final Color line;
  final Color accent;
  final Color accentInk;
  final Color accentSoft;
  final Color warm;
  final Color warmSoft;
  final Color danger;
  final Color dangerSoft;
  final Color playerBg;
  final Color playerInk;
  final Color playerDim;

  /// The far arm/leg of a [StretchFigure] illustration — the prototype's
  /// `--fig-far`. Distinct from [ink3]: this is a decorative line weight,
  /// not text, so it isn't held to the same contrast ratio.
  final Color figFar;

  final Color scrim;
  final Color shadow;

  static const Color white = Color(0xFFFFFFFF);

  static const light = AppColors(
    ground: Color(0xFFEDF1EC),
    surface: Color(0xFFFFFFFF),
    surface2: Color(0xFFE1E8E0),
    ink: Color(0xFF15201B),
    ink2: Color(0xFF4F5E57),
    // Darker than the prototype's #7A8881 so small captions pass 4.5:1 on ground.
    ink3: Color(0xFF66746D),
    line: Color(0xFFD2DAD2),
    accent: Color(0xFF1C6A56),
    accentInk: Color(0xFFFFFFFF),
    accentSoft: Color(0xFFD4E7DE),
    warm: Color(0xFFB9661A),
    warmSoft: Color(0xFFF6E4CD),
    danger: Color(0xFFB3382F),
    dangerSoft: Color(0xFFF6DEDB),
    playerBg: Color(0xFF10362D),
    playerInk: Color(0xFFEAF4EF),
    playerDim: Color(0xFF9CC4B6),
    figFar: Color(0xFFA3B3AB),
    scrim: Color(0x73060E0A),
    shadow: Color(0x1A14281E),
  );

  static const dark = AppColors(
    ground: Color(0xFF0D1411),
    surface: Color(0xFF151D1A),
    surface2: Color(0xFF1F2925),
    ink: Color(0xFFE3EBE6),
    ink2: Color(0xFFA3B2AB),
    ink3: Color(0xFF7E8E86),
    line: Color(0xFF2A3531),
    accent: Color(0xFF5DC2A3),
    accentInk: Color(0xFF06231A),
    accentSoft: Color(0xFF17362D),
    warm: Color(0xFFEFA24E),
    warmSoft: Color(0xFF3A2A17),
    danger: Color(0xFFEE7B70),
    dangerSoft: Color(0xFF3A1D1A),
    playerBg: Color(0xFF0A1F19),
    playerInk: Color(0xFFE6F2EC),
    playerDim: Color(0xFF86B3A4),
    figFar: Color(0xFF5C6D65),
    scrim: Color(0x99000000),
    shadow: Color(0x59000000),
  );

  @override
  AppColors copyWith({
    Color? ground,
    Color? surface,
    Color? surface2,
    Color? ink,
    Color? ink2,
    Color? ink3,
    Color? line,
    Color? accent,
    Color? accentInk,
    Color? accentSoft,
    Color? warm,
    Color? warmSoft,
    Color? danger,
    Color? dangerSoft,
    Color? playerBg,
    Color? playerInk,
    Color? playerDim,
    Color? figFar,
    Color? scrim,
    Color? shadow,
  }) => AppColors(
    ground: ground ?? this.ground,
    surface: surface ?? this.surface,
    surface2: surface2 ?? this.surface2,
    ink: ink ?? this.ink,
    ink2: ink2 ?? this.ink2,
    ink3: ink3 ?? this.ink3,
    line: line ?? this.line,
    accent: accent ?? this.accent,
    accentInk: accentInk ?? this.accentInk,
    accentSoft: accentSoft ?? this.accentSoft,
    warm: warm ?? this.warm,
    warmSoft: warmSoft ?? this.warmSoft,
    danger: danger ?? this.danger,
    dangerSoft: dangerSoft ?? this.dangerSoft,
    playerBg: playerBg ?? this.playerBg,
    playerInk: playerInk ?? this.playerInk,
    playerDim: playerDim ?? this.playerDim,
    figFar: figFar ?? this.figFar,
    scrim: scrim ?? this.scrim,
    shadow: shadow ?? this.shadow,
  );

  @override
  AppColors lerp(AppColors? other, double t) {
    if (other == null) return this;
    Color mix(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppColors(
      ground: mix(ground, other.ground),
      surface: mix(surface, other.surface),
      surface2: mix(surface2, other.surface2),
      ink: mix(ink, other.ink),
      ink2: mix(ink2, other.ink2),
      ink3: mix(ink3, other.ink3),
      line: mix(line, other.line),
      accent: mix(accent, other.accent),
      accentInk: mix(accentInk, other.accentInk),
      accentSoft: mix(accentSoft, other.accentSoft),
      warm: mix(warm, other.warm),
      warmSoft: mix(warmSoft, other.warmSoft),
      danger: mix(danger, other.danger),
      dangerSoft: mix(dangerSoft, other.dangerSoft),
      playerBg: mix(playerBg, other.playerBg),
      playerInk: mix(playerInk, other.playerInk),
      playerDim: mix(playerDim, other.playerDim),
      figFar: mix(figFar, other.figFar),
      scrim: mix(scrim, other.scrim),
      shadow: mix(shadow, other.shadow),
    );
  }
}

extension AppColorsContext on BuildContext {
  AppColors get colors => Theme.of(this).extension<AppColors>()!;
}
