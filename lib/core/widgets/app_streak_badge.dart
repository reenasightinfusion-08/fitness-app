import 'package:flutter/material.dart';

import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:fitness_app/core/theme/theme.dart';

class AppStreakBadge extends StatelessWidget {
  const AppStreakBadge({super.key, required this.days, this.isLarge = false});

  final int days;
  final bool isLarge;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Semantics(
      label: 'Current streak: $days ${days == 1 ? 'day' : 'days'}',
      excludeSemantics: true,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isLarge ? 14.w : 11.w,
          vertical: isLarge ? 9.h : 7.h,
        ),
        decoration: BoxDecoration(
          color: colors.warmSoft,
          borderRadius: AppBorderRadius.pill,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.local_fire_department_rounded,
              size: 16.r,
              color: colors.warm,
            ),
            5.horizontalSpace,
            Text(
              '$days ${days == 1 ? 'day' : 'days'}',
              style:
                  (isLarge ? AppTextStyle.titleSmall : AppTextStyle.bodySmall)
                      .copyWith(
                        color: colors.warm,
                        fontWeight: FontWeight.w800,
                        fontFeatures: AppTextStyle.tabular,
                      ),
            ),
          ],
        ),
      ),
    );
  }
}
