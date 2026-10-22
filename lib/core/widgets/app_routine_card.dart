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
    this.badge,
  });

  final String title;
  final String meta;
  final VoidCallback? onTap;
  final Widget? thumbnail;

  /// Accent tag under the meta line, e.g. "Adapted for you · 2 swaps".
  final String? badge;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final size = MediaQuery.sizeOf(context);
    final isTablet = size.width >= 600;

    return Material(
      color: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius:
            isTablet ? BorderRadius.circular(18.0) : AppBorderRadius.xxl,
        side: BorderSide(color: colors.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.all(isTablet ? 14.0 : 12.r),
          child: Row(
            children: [
              thumbnail ?? const AppThumb(size: AppThumbSize.large),
              (isTablet ? 16.0 : 14.0).horizontalSpace,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: isTablet ? 8.0 : 6.w,
                      runSpacing: isTablet ? 4.0 : 4.h,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          title,
                          style: AppTextStyle.titleMedium.copyWith(
                            fontSize: isTablet ? 16.5 : null,
                          ),
                        ),
                      ],
                    ),
                    (isTablet ? 3.0 : 2.0).verticalSpace,
                    Text(
                      meta,
                      style: AppTextStyle.meta.copyWith(
                        color: colors.ink2,
                        fontSize: isTablet ? 13.5 : null,
                      ),
                    ),
                    if (badge != null) ...[
                      (isTablet ? 6.0 : 6.0).verticalSpace,
                      AppTag(label: badge!, tone: AppTone.accent),
                    ],
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: isTablet ? 22.0 : 20.r,
                color: colors.ink3,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
