import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:fitness_app/core/theme/theme.dart';
import 'package:fitness_app/core/widgets/widgets.dart';
import 'package:fitness_app/features/onboarding_setup/models/onboarding_profile.dart';
import 'package:fitness_app/features/onboarding_setup/providers/onboarding_profile_provider.dart';
import 'package:fitness_app/features/onboarding_setup/widgets/steps/flexibility_step.dart';

/// Screen allowing the user to re-assess their flexibility level from Progress screen.
class FlexibilityCheckScreen extends ConsumerWidget {
  const FlexibilityCheckScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final profile = ref.watch(onboardingProfileProvider);
    final allAnswered = profile.flexAnswers.every((answer) => answer != null);
    final level = calcFlexibilityLevel(profile.flexAnswers);

    return Scaffold(
      backgroundColor: colors.ground,
      appBar: AppTopBar(
        title: 'Flexibility level',
        onBack: () => Navigator.of(context).pop(),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: AppInsets.page,
                children: [
                  Text(
                    'Retake flexibility check',
                    style: AppTextStyle.headline,
                  ),
                  6.verticalSpace,
                  Text(
                    'Re-evaluate your range of motion as you loosen up.',
                    style: AppTextStyle.meta.copyWith(color: colors.ink2),
                  ),
                  20.verticalSpace,
                  const FlexibilityStep(),
                ],
              ),
            ),
            if (allAnswered)
              Padding(
                padding: AppInsets.page,
                child: AppButton(
                  label: 'Done · Save level (${flexibilityLevelLabels[level]})',
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
