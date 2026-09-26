import 'package:flutter/material.dart';

import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:fitness_app/core/theme/theme.dart';
import 'package:fitness_app/features/onboarding/models/onboarding_page_model.dart';
import 'package:fitness_app/features/onboarding/widgets/onboarding_parallax.dart';
import 'package:fitness_app/features/onboarding/widgets/onboarding_step_heading.dart';

/// One onboarding step: transparent cut-out image and copy, stacked in the
/// order the page asks for. The image sits straight on the page background.
class OnboardingStepView extends StatelessWidget {
  const OnboardingStepView({
    super.key,
    required this.page,
    required this.index,
    required this.controller,
  });

  final OnboardingPageModel page;
  final int index;
  final PageController controller;

  @override
  Widget build(BuildContext context) {
    final heading = Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      child: OnboardingParallax(
        controller: controller,
        index: index,
        child: OnboardingStepHeading(page: page),
      ),
    );
    final image = Expanded(
      child: OnboardingParallax(
        controller: controller,
        index: index,
        shift: 36,
        shouldFade: false,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 8.w),
          child: OnboardingImage(page: page),
        ),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: page.isImageFirst
          ? [image, 16.verticalSpace, heading]
          : [8.verticalSpace, heading, 16.verticalSpace, image],
    );
  }
}

class OnboardingImage extends StatelessWidget {
  const OnboardingImage({super.key, required this.page});

  final OnboardingPageModel page;

  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.expand,
    children: [
      Image.asset(
        page.imagePath,
        fit: BoxFit.contain,
        alignment: page.imageAlignment,
        semanticLabel: page.imageLabel,
        filterQuality: FilterQuality.medium,
      ),
      if (page.note != null)
        Positioned(
          top: 8.h,
          right: 16.w,
          child: Transform.rotate(
            angle: -0.14,
            child: Text(
              page.note!,
              textAlign: TextAlign.right,
              style: AppTextStyle.script.copyWith(color: context.colors.accent),
            ),
          ),
        ),
    ],
  );
}
