import 'package:flutter/material.dart';

import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:fitness_app/core/theme/theme.dart';

enum AppTone { neutral, accent, warm, danger }

class AppTag extends StatelessWidget {
  const AppTag({
    super.key,
    required this.label,
    this.tone = AppTone.neutral,
    this.icon,
  });

  final String label;
  final AppTone tone;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final (background, foreground) = switch (tone) {
      AppTone.neutral => (colors.surface2, colors.ink2),
      AppTone.accent => (colors.accentSoft, colors.accent),
      AppTone.warm => (colors.warmSoft, colors.warm),
      AppTone.danger => (colors.dangerSoft, colors.danger),
    };

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: background,
        borderRadius: AppBorderRadius.pill,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12.r, color: foreground),
            4.horizontalSpace,
          ],
          Text(label, style: AppTextStyle.tag.copyWith(color: foreground)),
        ],
      ),
    );
  }
}
