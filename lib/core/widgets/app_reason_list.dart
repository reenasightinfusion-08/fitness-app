import 'package:flutter/material.dart';

import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:fitness_app/core/theme/theme.dart';

/// Icon-led bullet list ("Why these stretches", safety points).
class AppReasonList extends StatelessWidget {
  const AppReasonList({
    super.key,
    required this.items,
    this.icon = Icons.check_rounded,
  });

  final List<String> items;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < items.length; i++) ...[
          if (i > 0) 9.verticalSpace,
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.only(top: 2.h),
                child: Icon(icon, size: 18.r, color: colors.accent),
              ),
              10.horizontalSpace,
              Expanded(child: Text(items[i], style: AppTextStyle.bodyMedium)),
            ],
          ),
        ],
      ],
    );
  }
}
