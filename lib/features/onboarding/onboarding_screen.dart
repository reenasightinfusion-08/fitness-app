import 'package:flutter/material.dart';

import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:fitness_app/core/widgets/widgets.dart';
import 'package:fitness_app/features/onboarding/models/onboarding_page_model.dart';
import 'package:fitness_app/features/onboarding/widgets/onboarding_footer.dart';
import 'package:fitness_app/features/onboarding/widgets/onboarding_step_view.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({
    super.key,
    required this.onFinish,
    required this.onLogin,
  });

  final VoidCallback onFinish;
  final VoidCallback onLogin;

  @override
  State<OnboardingScreen> createState() => OnboardingScreenState();
}

class OnboardingScreenState extends State<OnboardingScreen> {
  final PageController controller = PageController();
  int currentIndex = 0;

  static const List<OnboardingPageModel> pages = OnboardingPageModel.pages;

  bool get isLastPage => currentIndex == pages.length - 1;

  void goNext() {
    if (isLastPage) {
      widget.onFinish();
      return;
    }
    controller.nextPage(
      duration: const Duration(milliseconds: 520),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(24.w, 8.h, 12.w, 8.h),
            child: Row(
              children: [
                const AppBrandLogo(),
                const Spacer(),
                AppButton(
                  label: isLastPage ? 'Log in' : 'Skip',
                  variant: AppButtonVariant.text,
                  size: AppButtonSize.small,
                  isExpanded: false,
                  onPressed: isLastPage ? widget.onLogin : widget.onFinish,
                ),
              ],
            ),
          ),
          Expanded(
            child: PageView.builder(
              controller: controller,
              itemCount: pages.length,
              onPageChanged: (index) => setState(() => currentIndex = index),
              itemBuilder: (context, index) => OnboardingStepView(
                page: pages[index],
                index: index,
                controller: controller,
              ),
            ),
          ),
          OnboardingFooter(
            pageCount: pages.length,
            currentIndex: currentIndex,
            onNext: goNext,
          ),
        ],
      ),
    ),
  );
}
