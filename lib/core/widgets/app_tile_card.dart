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
    final size = MediaQuery.sizeOf(context);
    final isTablet = size.width >= 600;

    final titleStyle = AppTextStyle.titleSmall.copyWith(
      fontSize: isTablet ? 15.0 : null,
      fontWeight: FontWeight.w700,
      height: 1.25,
    );
    final metaStyle = AppTextStyle.meta.copyWith(
      fontSize: isTablet ? 13.0 : null,
      color: colors.ink2,
    );

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
          padding: EdgeInsets.all(isTablet ? 14.0 : 12.r),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              thumbnail ??
                  const AppThumb(
                    size: AppThumbSize.medium,
                  ),
              (isTablet ? 8.0 : 6.0).verticalSpace,
              const Spacer(),
              Text(title, style: titleStyle),
              if (meta != null) ...[
                2.verticalSpace,
                Text(meta!, style: metaStyle),
              ],
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
