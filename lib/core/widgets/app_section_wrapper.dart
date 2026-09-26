import 'package:flutter/material.dart';

import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:fitness_app/core/theme/theme.dart';

/// Titled section: "Quick picks", "This week", "Your routines"…
class AppSectionWrapper extends StatelessWidget {
  const AppSectionWrapper({
    super.key,
    required this.title,
    required this.child,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final Widget child;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
              child: Semantics(
                header: true,
                child: Text(title, style: AppTextStyle.sectionTitle),
              ),
            ),
            if (actionLabel != null)
              InkWell(
                onTap: onAction,
                borderRadius: AppBorderRadius.xs,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 4.h),
                  child: Text(
                    actionLabel!,
                    style: AppTextStyle.label.copyWith(color: colors.accent),
                  ),
                ),
              ),
          ],
        ),
        10.verticalSpace,
        child,
      ],
    );
  }
}
