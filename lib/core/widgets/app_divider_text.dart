import 'package:flutter/material.dart';

import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:fitness_app/core/theme/theme.dart';

/// ─── or use email ───
class AppDividerText extends StatelessWidget {
  const AppDividerText({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Row(
      children: [
        Expanded(child: Divider(color: colors.line, height: 1)),
        10.horizontalSpace,
        Text(text, style: AppTextStyle.meta.copyWith(color: colors.ink3)),
        10.horizontalSpace,
        Expanded(child: Divider(color: colors.line, height: 1)),
      ],
    );
  }
}
