import 'package:flutter/material.dart';

import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:fitness_app/core/theme/theme.dart';
import 'package:fitness_app/core/widgets/app_tag.dart';
import 'package:fitness_app/core/widgets/app_thumb.dart';

class AppRoutineCard extends StatelessWidget {
  const AppRoutineCard({
    super.key,
    required this.title,
    required this.meta,
    required this.onTap,
    this.thumbnail,
    this.isLocked = false,
    this.badge,
  });

  final String title;
  final String meta;
  final VoidCallback? onTap;
  final Widget? thumbnail;
  final bool isLocked;

  /// Accent tag under the meta line, e.g. "Adapted for you · 2 swaps".
  final String? badge;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Material(
      color: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: AppBorderRadius.xxl,
        side: BorderSide(color: colors.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.all(12.r),
          child: Row(
            children: [
              thumbnail ?? const AppThumb(size: AppThumbSize.large),
              14.horizontalSpace,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 6.w,
                      runSpacing: 4.h,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(title, style: AppTextStyle.titleMedium),
                        if (isLocked)
                          const AppTag(
                            label: 'Premium',
                            icon: Icons.lock_rounded,
                          ),
                      ],
                    ),
                    2.verticalSpace,
                    Text(
                      meta,
                      style: AppTextStyle.meta.copyWith(color: colors.ink2),
                    ),
                    if (badge != null) ...[
                      6.verticalSpace,
                      AppTag(label: badge!, tone: AppTone.accent),
                    ],
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, size: 20.r, color: colors.ink3),
            ],
          ),
        ),
      ),
    );
  }
}
