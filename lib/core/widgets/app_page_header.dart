import 'package:flutter/material.dart';

import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:fitness_app/core/theme/theme.dart';

/// Eyebrow + display title + optional subtitle and "why we ask" hint.
class AppPageHeader extends StatelessWidget {
  const AppPageHeader({
    super.key,
    required this.title,
    this.eyebrow,
    this.subtitle,
    this.hint,
    this.trailing,
  });

  final String title;
  final String? eyebrow;
  final String? subtitle;

  /// Shown with an info icon — explains why a question is asked.
  final String? hint;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (eyebrow != null) ...[
                Text(
                  eyebrow!.toUpperCase(),
                  style: AppTextStyle.eyebrow.copyWith(color: colors.ink3),
                ),
                4.verticalSpace,
              ],
              Semantics(
                header: true,
                child: Text(title, style: AppTextStyle.headline),
              ),
              if (subtitle != null) ...[
                6.verticalSpace,
                Text(
                  subtitle!,
                  style: AppTextStyle.bodyMedium.copyWith(color: colors.ink2),
                ),
              ],
              if (hint != null) ...[
                8.verticalSpace,
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: EdgeInsets.only(top: 2.h),
                      child: Icon(
                        Icons.info_outline_rounded,
                        size: 16.r,
                        color: colors.accent,
                      ),
                    ),
                    6.horizontalSpace,
                    Expanded(
                      child: Text(
                        hint!,
                        style: AppTextStyle.bodySmall.copyWith(
                          color: colors.ink2,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        if (trailing != null) ...[12.horizontalSpace, trailing!],
      ],
    );
  }
}
