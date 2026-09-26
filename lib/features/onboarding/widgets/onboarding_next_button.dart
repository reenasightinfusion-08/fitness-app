import 'package:flutter/material.dart';

import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:fitness_app/core/theme/theme.dart';

/// Round arrow button that stretches into "Get started →" on the last step.
class OnboardingNextButton extends StatelessWidget {
  const OnboardingNextButton({
    super.key,
    required this.isLastPage,
    required this.onPressed,
  });

  final bool isLastPage;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final foreground = colors.accentInk;
    return Semantics(
      button: true,
      label: isLastPage ? 'Get started' : 'Next step',
      excludeSemantics: true,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 380),
        curve: Curves.easeOutBack,
        width: isLastPage ? 176.w : 60.r,
        height: 60.r,
        decoration: BoxDecoration(
          color: colors.accent,
          borderRadius: AppBorderRadius.pill,
          boxShadow: [
            BoxShadow(
              color: colors.accent.withValues(alpha: 0.3),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: onPressed,
            borderRadius: AppBorderRadius.pill,
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 18.w),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedSize(
                        duration: const Duration(milliseconds: 300),
                        child: isLastPage
                            ? Padding(
                                padding: EdgeInsets.only(right: 10.w),
                                child: Text(
                                  'Get started',
                                  style: AppTextStyle.button.copyWith(
                                    color: foreground,
                                  ),
                                ),
                              )
                            : const SizedBox.shrink(),
                      ),
                      Icon(
                        Icons.arrow_forward_rounded,
                        size: 24.r,
                        color: foreground,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
