import 'package:flutter/material.dart';

import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:fitness_app/core/theme/theme.dart';
import 'package:fitness_app/core/widgets/app_tag.dart';

/// The prototype's toast, as a floating snackbar with a tone icon.
class AppSnackBar {
  const AppSnackBar._();

  static void show(
    BuildContext context,
    String message, {
    AppTone tone = AppTone.neutral,
  }) {
    final colors = context.colors;
    final (icon, iconColor) = switch (tone) {
      AppTone.neutral => (Icons.info_outline_rounded, colors.ground),
      AppTone.accent => (Icons.check_circle_rounded, colors.accentSoft),
      AppTone.warm => (Icons.schedule_rounded, colors.warmSoft),
      AppTone.danger => (Icons.error_rounded, colors.dangerSoft),
    };

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: colors.ink,
          elevation: 6,
          duration: const Duration(milliseconds: 2800),
          margin: EdgeInsets.fromLTRB(18.w, 0, 18.w, 16.h),
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
          shape: RoundedRectangleBorder(borderRadius: AppBorderRadius.lg),
          content: Row(
            children: [
              Icon(icon, size: 20.r, color: iconColor),
              10.horizontalSpace,
              Expanded(
                child: Text(
                  message,
                  style: AppTextStyle.bodySmall.copyWith(
                    color: colors.ground,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
  }

  static void showSuccess(BuildContext context, String message) =>
      show(context, message, tone: AppTone.accent);

  static void showError(BuildContext context, String message) =>
      show(context, message, tone: AppTone.danger);
}
