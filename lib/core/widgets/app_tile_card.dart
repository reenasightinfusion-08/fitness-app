import 'package:flutter/material.dart';

import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:fitness_app/core/theme/theme.dart';
import 'package:fitness_app/core/widgets/app_thumb.dart';

/// Grid tile for quick picks and the stretch library.
class AppTileCard extends StatelessWidget {
  const AppTileCard({
    super.key,
    required this.title,
    required this.onTap,
    this.meta,
    this.thumbnail,
  });

  final String title;
  final String? meta;
  final VoidCallback? onTap;
  final Widget? thumbnail;

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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              thumbnail ?? const AppThumb(),
              10.verticalSpace,
              Text(
                title,
                style: AppTextStyle.titleSmall.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (meta != null)
                Text(
                  meta!,
                  style: AppTextStyle.meta.copyWith(color: colors.ink2),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
