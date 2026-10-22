import 'package:flutter/material.dart';

import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:fitness_app/core/theme/theme.dart';
import 'package:fitness_app/core/widgets/app_button.dart';
import 'package:fitness_app/core/widgets/app_thumb.dart';

/// Dark "Paused session" card on Today.
class AppResumeBanner extends StatelessWidget {
  const AppResumeBanner({
    super.key,
    required this.title,
    required this.subtitle,
    required this.onResume,
    this.eyebrow = 'Paused session',
    this.thumbnail,
  });

  final String eyebrow;
  final String title;
  final String subtitle;
  final VoidCallback onResume;
  final Widget? thumbnail;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final size = MediaQuery.sizeOf(context);
    final isTablet = size.width >= 600;

    final dimStyle = AppTextStyle.meta.copyWith(
      color: colors.playerDim,
      fontSize: isTablet ? 12.0 : null,
    );
    final titleStyle = AppTextStyle.titleMedium.copyWith(
      color: colors.playerInk,
      fontSize: isTablet ? 16.0 : null,
    );

    return Container(
      padding: EdgeInsets.all(isTablet ? 14.0 : 14.r),
      decoration: BoxDecoration(
        color: colors.playerBg,
        borderRadius: AppBorderRadius.xxl,
      ),
      child: Row(
        children: [
          thumbnail ??
              const AppThumb(
                size: AppThumbSize.medium,
                isOnDark: true,
              ),
          (isTablet ? 14.0 : 12.0).horizontalSpace,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(eyebrow, style: dimStyle),
                (isTablet ? 2.0 : 0.0).verticalSpace,
                Text(
                  title,
                  style: titleStyle,
                ),
                (isTablet ? 2.0 : 0.0).verticalSpace,
                Text(
                  subtitle,
                  style: dimStyle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          (isTablet ? 14.0 : 12.0).horizontalSpace,
          AppButton(
            label: 'Resume',
            icon: Icons.play_arrow_rounded,
            onPressed: onResume,
            variant: AppButtonVariant.inverse,
            size: AppButtonSize.small,
            isExpanded: false,
          ),
        ],
      ),
    );
  }
}
