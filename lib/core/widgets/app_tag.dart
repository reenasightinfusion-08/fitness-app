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

    final size = MediaQuery.sizeOf(context);
    final isTablet = size.width >= 600;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isTablet ? 10.0 : (9.w).clamp(9.0, 16.0),
        vertical: isTablet ? 5.0 : (4.h).clamp(4.0, 8.0),
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: AppBorderRadius.pill,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: isTablet ? 14.0 : (12.r).clamp(12.0, 16.0),
              color: foreground,
            ),
            SizedBox(width: isTablet ? 5.0 : 4.0),
          ],
          Flexible(
            child: Text(
              label,
              style: AppTextStyle.tag.copyWith(
                color: foreground,
                fontSize: isTablet ? 12.0 : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
