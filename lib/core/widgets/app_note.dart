import 'package:flutter/material.dart';

import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:fitness_app/core/theme/theme.dart';
import 'package:fitness_app/core/widgets/app_tag.dart';

/// Inline callout (plan level, safety warning, demo code). Carries an icon
/// so the tone isn't conveyed by background color alone.
class AppNote extends StatelessWidget {
  const AppNote({
    super.key,
    required this.message,
    this.title,
    this.tone = AppTone.accent,
    this.icon,
  });

  final String message;
  final String? title;
  final AppTone tone;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final (background, foreground, defaultIcon) = switch (tone) {
      AppTone.neutral => (
        colors.surface2,
        colors.ink2,
        Icons.info_outline_rounded,
      ),
      AppTone.accent => (
        colors.accentSoft,
        colors.accent,
        Icons.check_circle_outline_rounded,
      ),
      AppTone.warm => (
        colors.warmSoft,
        colors.warm,
        Icons.lightbulb_outline_rounded,
      ),
      AppTone.danger => (
        colors.dangerSoft,
        colors.danger,
        Icons.error_outline_rounded,
      ),
    };

    final size = MediaQuery.sizeOf(context);
    final isTablet = size.width >= 600;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isTablet ? 14.0 : 14.w,
        vertical: isTablet ? 12.0 : 12.h,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: AppBorderRadius.xl,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon ?? defaultIcon,
            size: isTablet ? 20.0 : 20.r,
            color: foreground,
          ),
          (isTablet ? 10.0 : 10.0).horizontalSpace,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (title != null)
                  Text(
                    title!,
                    style: AppTextStyle.titleSmall.copyWith(
                      fontSize: isTablet ? 15.0 : null,
                    ),
                  ),
                if (title != null && isTablet) 4.verticalSpace,
                Text(
                  message,
                  style: AppTextStyle.bodySmall.copyWith(
                    fontSize: isTablet ? 13.5 : null,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
