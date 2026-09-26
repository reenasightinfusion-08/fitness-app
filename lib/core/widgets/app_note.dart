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

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: background,
        borderRadius: AppBorderRadius.xl,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon ?? defaultIcon, size: 20.r, color: foreground),
          10.horizontalSpace,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (title != null) Text(title!, style: AppTextStyle.titleSmall),
                Text(message, style: AppTextStyle.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
