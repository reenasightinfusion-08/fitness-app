import 'package:flutter/material.dart';

import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:fitness_app/core/theme/theme.dart';
import 'package:fitness_app/core/widgets/app_card.dart';

/// Small label/value pair (Routine detail: Time, Level, Position).
class AppFactTile extends StatelessWidget {
  const AppFactTile({super.key, required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => AppCard(
    padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
    borderRadius: AppBorderRadius.lg,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: AppTextStyle.eyebrow.copyWith(color: context.colors.ink3),
        ),
        2.verticalSpace,
        Text(
          value,
          style: AppTextStyle.bodySmall.copyWith(fontWeight: FontWeight.w700),
        ),
      ],
    ),
  );
}
