import 'package:flutter/material.dart';

import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:fitness_app/core/theme/theme.dart';
import 'package:fitness_app/core/widgets/app_button.dart';

/// Replaces the prototype's bare dashed box with an icon, a line of
/// guidance and an optional next action.
class AppEmptyState extends StatelessWidget {
  const AppEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 24.h),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: AppBorderRadius.card,
        border: Border.all(color: colors.line),
      ),
      child: Column(
        children: [
          Container(
            width: 56.r,
            height: 56.r,
            decoration: BoxDecoration(
              color: colors.accentSoft,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 26.r, color: colors.accent),
          ),
          12.verticalSpace,
          Text(
            title,
            style: AppTextStyle.titleMedium,
            textAlign: TextAlign.center,
          ),
          if (message != null) ...[
            4.verticalSpace,
            Text(
              message!,
              style: AppTextStyle.bodySmall.copyWith(color: colors.ink2),
              textAlign: TextAlign.center,
            ),
          ],
          if (actionLabel != null) ...[
            16.verticalSpace,
            AppButton(
              label: actionLabel!,
              onPressed: onAction,
              variant: AppButtonVariant.secondary,
              size: AppButtonSize.small,
              isExpanded: false,
            ),
          ],
        ],
      ),
    );
  }
}
