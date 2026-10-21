import 'package:flutter/material.dart';

import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:fitness_app/core/theme/theme.dart';

/// Shared look for [AppTextField] and [AppDropDown] so both stay identical.
class AppInputDecoration {
  const AppInputDecoration._();

  static OutlineInputBorder border(
    Color color, {
    double width = 1,
    double? radius,
  }) => OutlineInputBorder(
    borderRadius: radius != null
        ? BorderRadius.circular(radius)
        : AppBorderRadius.lg,
    borderSide: BorderSide(color: color, width: width),
  );

  static InputDecoration build(
    AppColors colors, {
    String? hint,
    Widget? prefixIcon,
    Widget? suffixIcon,
    bool isTablet = false,
    double? fontSize,
    EdgeInsetsGeometry? contentPadding,
  }) {
    final effectiveFontSize = fontSize ?? (isTablet ? 21.0 : null);
    final effectivePadding =
        contentPadding ??
        (isTablet
            ? const EdgeInsets.symmetric(horizontal: 22.0, vertical: 20.0)
            : EdgeInsets.symmetric(horizontal: 14.w, vertical: 15.h));

    return InputDecoration(
      hintText: hint,
      hintStyle: effectiveFontSize != null
          ? AppTextStyle.bodyLarge.copyWith(
              color: colors.ink3,
              fontSize: effectiveFontSize,
            )
          : AppTextStyle.bodyLarge.copyWith(color: colors.ink3),
      filled: true,
      fillColor: colors.surface,
      isDense: !isTablet,
      contentPadding: effectivePadding,
      prefixIcon: prefixIcon,
      prefixIconColor: colors.ink3,
      suffixIcon: suffixIcon,
      suffixIconColor: colors.ink2,
      counterText: '',
      errorStyle: AppTextStyle.meta.copyWith(
        color: colors.danger,
        fontWeight: FontWeight.w600,
        fontSize: isTablet ? 14.0 : null,
      ),
      errorMaxLines: 2,
      border: border(colors.line, radius: isTablet ? 16.0 : null),
      enabledBorder: border(colors.line, radius: isTablet ? 16.0 : null),
      focusedBorder: border(
        colors.accent,
        width: 1.8,
        radius: isTablet ? 16.0 : null,
      ),
      errorBorder: border(colors.danger, radius: isTablet ? 16.0 : null),
      focusedErrorBorder: border(
        colors.danger,
        width: 1.8,
        radius: isTablet ? 16.0 : null,
      ),
      disabledBorder: border(
        colors.line.withValues(alpha: 0.5),
        radius: isTablet ? 16.0 : null,
      ),
    );
  }
}
