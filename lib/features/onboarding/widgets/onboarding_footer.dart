import 'package:flutter/material.dart';

import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:fitness_app/features/onboarding/widgets/onboarding_next_button.dart';
import 'package:fitness_app/features/onboarding/widgets/stretch_page_indicator.dart';

class OnboardingFooter extends StatelessWidget {
  const OnboardingFooter({
    super.key,
    required this.pageCount,
    required this.currentIndex,
    required this.onNext,
  });

  final int pageCount;
  final int currentIndex;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(24.w, 16.h, 24.w, 16.h),
    child: Row(
      children: [
        StretchPageIndicator(count: pageCount, currentIndex: currentIndex),
        const Spacer(),
        OnboardingNextButton(
          isLastPage: currentIndex == pageCount - 1,
          onPressed: onNext,
        ),
      ],
    ),
  );
}
