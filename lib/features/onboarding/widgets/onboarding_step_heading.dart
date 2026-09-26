import 'package:flutter/material.dart';

import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:fitness_app/core/theme/theme.dart';
import 'package:fitness_app/features/onboarding/models/onboarding_page_model.dart';

/// STEP 0X · two-tone title · supporting line.
class OnboardingStepHeading extends StatelessWidget {
  const OnboardingStepHeading({super.key, required this.page});

  final OnboardingPageModel page;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          page.stepLabel,
          style: AppTextStyle.eyebrow.copyWith(
            color: colors.accent,
            letterSpacing: 2,
          ),
        ),
        10.verticalSpace,
        Semantics(
          header: true,
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(text: '${page.titleLead}\n'),
                TextSpan(
                  text: page.titleAccent,
                  style: TextStyle(color: colors.accent),
                ),
              ],
            ),
            style: AppTextStyle.headlineLarge.copyWith(color: colors.ink),
          ),
        ),
        12.verticalSpace,
        Text(
          page.body,
          style: AppTextStyle.bodyMedium.copyWith(color: colors.ink2),
        ),
      ],
    );
  }
}
