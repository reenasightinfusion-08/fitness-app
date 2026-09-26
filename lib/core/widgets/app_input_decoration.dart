import 'package:flutter/material.dart';

import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:fitness_app/core/theme/theme.dart';

/// Shared look for [AppTextField] and [AppDropDown] so both stay identical.
class AppInputDecoration {
  const AppInputDecoration._();

  static OutlineInputBorder border(Color color, {double width = 1}) =>
      OutlineInputBorder(
        borderRadius: AppBorderRadius.lg,
        borderSide: BorderSide(color: color, width: width),
      );

  static InputDecoration build(
    AppColors colors, {
    String? hint,
    Widget? prefixIcon,
    Widget? suffixIcon,
  }) => InputDecoration(
    hintText: hint,
    hintStyle: AppTextStyle.bodyLarge.copyWith(color: colors.ink3),
    filled: true,
    fillColor: colors.surface,
    isDense: true,
    contentPadding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 15.h),
    prefixIcon: prefixIcon,
    prefixIconColor: colors.ink3,
    suffixIcon: suffixIcon,
    suffixIconColor: colors.ink2,
    counterText: '',
    errorStyle: AppTextStyle.meta.copyWith(
      color: colors.danger,
      fontWeight: FontWeight.w600,
    ),
    errorMaxLines: 2,
    border: border(colors.line),
    enabledBorder: border(colors.line),
    focusedBorder: border(colors.accent, width: 1.5),
    errorBorder: border(colors.danger),
    focusedErrorBorder: border(colors.danger, width: 1.5),
    disabledBorder: border(colors.line.withValues(alpha: 0.5)),
  );
}
