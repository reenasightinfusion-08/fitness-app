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
    final size = MediaQuery.sizeOf(context);
    final isTablet = size.width >= 600;
    final h = size.height;

    final textFontSize = isTablet ? (h * 0.024).clamp(18.0, 26.0) : null;
    final iconSize = isTablet ? (h * 0.028).clamp(22.0, 32.0) : 18.r;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < items.length; i++) ...[
          if (i > 0) (isTablet ? 14.0 : 9.0).verticalSpace,
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.only(top: isTablet ? 3.0 : 2.h),
                child: Icon(icon, size: iconSize, color: colors.accent),
              ),
              (isTablet ? 14.0 : 10.0).horizontalSpace,
              Expanded(
                child: Text(
                  items[i],
                  style: AppTextStyle.bodyMedium.copyWith(
                    fontSize: textFontSize,
                    height: 1.45,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
