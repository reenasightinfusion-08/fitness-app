import 'package:flutter/material.dart';

import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

/// Every font size in the app lives here. Widgets override only `color`
/// or `fontWeight` via `copyWith`.
///
/// Colors are left unset so text inherits `ink` from the theme and flips
/// with dark mode.
class AppTextStyle {
  const AppTextStyle._();

  static const List<FontFeature> tabular = [FontFeature.tabularFigures()];

  static TextStyle display(
    double size, {
    FontWeight weight = FontWeight.w700,
  }) => GoogleFonts.bricolageGrotesque(
    fontSize: size.sp,
    fontWeight: weight,
    height: 1.1,
    letterSpacing: -0.02 * size.sp,
  );

  static TextStyle body(double size, {FontWeight weight = FontWeight.w400}) =>
      GoogleFonts.figtree(fontSize: size.sp, fontWeight: weight, height: 1.45);

  // Display
  static TextStyle get timer =>
      display(84).copyWith(height: 1, fontFeatures: tabular);
  static TextStyle get hero => display(40).copyWith(height: 1);
  static TextStyle get brandWord => display(24, weight: FontWeight.w800);
  static TextStyle get headlineLarge => display(34).copyWith(height: 1.05);
  static TextStyle get headline => display(28);
  static TextStyle get titleLarge => display(22).copyWith(height: 1.15);
  static TextStyle get sectionTitle => display(18);
  static TextStyle get statNumber =>
      display(28).copyWith(height: 1, fontFeatures: tabular);
  static TextStyle get avatar => display(26, weight: FontWeight.w800);

  /// Hand-written accent lines on imagery ("Feel lighter"). Use sparingly.
  static TextStyle get script => GoogleFonts.sacramento(
    fontSize: 38.sp,
    height: 1,
    fontWeight: FontWeight.w400,
  );

  // Body
  static TextStyle get titleMedium => body(16, weight: FontWeight.w700);
  static TextStyle get titleSmall => body(15, weight: FontWeight.w600);
  static TextStyle get bodyLarge => body(16);
  static TextStyle get bodyMedium => body(15);
  static TextStyle get bodySmall => body(14);
  static TextStyle get meta => body(13);
  static TextStyle get caption => body(12);
  static TextStyle get label => body(13, weight: FontWeight.w700);
  static TextStyle get eyebrow => body(
    11.5,
    weight: FontWeight.w700,
  ).copyWith(letterSpacing: 0.9, height: 1.2);
  static TextStyle get tag =>
      body(12, weight: FontWeight.w700).copyWith(height: 1.2);
  static TextStyle get tab =>
      body(11, weight: FontWeight.w700).copyWith(height: 1.2);
  static TextStyle get button =>
      body(16, weight: FontWeight.w700).copyWith(height: 1.2);
  static TextStyle get buttonSmall =>
      body(14, weight: FontWeight.w700).copyWith(height: 1.2);
  static TextStyle get chip =>
      body(14, weight: FontWeight.w600).copyWith(height: 1.2);
  static TextStyle get otp =>
      body(22, weight: FontWeight.w700).copyWith(letterSpacing: 8);
  static TextStyle get numeric => body(
    13,
    weight: FontWeight.w700,
  ).copyWith(fontFeatures: tabular, height: 1.2);
}
