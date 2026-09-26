import 'package:flutter/material.dart';

import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:fitness_app/core/theme/theme.dart';

/// "Already have an account? Log in"
class AppInlineLink extends StatelessWidget {
  const AppInlineLink({
    super.key,
    required this.linkText,
    required this.onTap,
    this.prefix,
  });

  final String? prefix;
  final String linkText;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (prefix != null)
          Text(
            '${prefix!} ',
            style: AppTextStyle.meta.copyWith(color: colors.ink2),
          ),
        InkWell(
          onTap: onTap,
          borderRadius: AppBorderRadius.xs,
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 6.h, horizontal: 2.w),
            child: Text(
              linkText,
              style: AppTextStyle.meta.copyWith(
                color: colors.accent,
                fontWeight: FontWeight.w700,
                decoration: TextDecoration.underline,
                decorationColor: colors.accent,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
