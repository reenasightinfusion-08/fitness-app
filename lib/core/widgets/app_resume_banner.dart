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
    final dimStyle = AppTextStyle.meta.copyWith(color: colors.playerDim);
    return Container(
      padding: EdgeInsets.all(14.r),
      decoration: BoxDecoration(
        color: colors.playerBg,
        borderRadius: AppBorderRadius.xxl,
      ),
      child: Row(
        children: [
          thumbnail ?? const AppThumb(isOnDark: true),
          12.horizontalSpace,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(eyebrow, style: dimStyle),
                Text(
                  title,
                  style: AppTextStyle.titleMedium.copyWith(
                    color: colors.playerInk,
                  ),
                ),
                Text(
                  subtitle,
                  style: dimStyle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          12.horizontalSpace,
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
