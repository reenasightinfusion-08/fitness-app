import 'package:flutter/material.dart';

import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:fitness_app/core/theme/theme.dart';
import 'package:fitness_app/core/widgets/app_card.dart';

/// Big number + caption (Progress: sessions, minutes, streak).
class AppStatTile extends StatelessWidget {
  const AppStatTile({super.key, required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) => AppCard(
    padding: EdgeInsets.all(12.r),
    borderRadius: AppBorderRadius.xl,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value, style: AppTextStyle.statNumber),
        4.verticalSpace,
        Text(
          label,
          style: AppTextStyle.caption.copyWith(color: context.colors.ink2),
        ),
      ],
    ),
  );
}
