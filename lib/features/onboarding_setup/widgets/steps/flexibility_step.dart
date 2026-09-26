import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:fitness_app/core/theme/theme.dart';
import 'package:fitness_app/core/widgets/widgets.dart';
import 'package:fitness_app/features/onboarding_setup/models/onboarding_options.dart';
import 'package:fitness_app/features/onboarding_setup/models/onboarding_profile.dart';
import 'package:fitness_app/features/onboarding_setup/providers/onboarding_profile_provider.dart';

/// Step 7 — three quick self-assessment questions, each illustrated with
/// the pose it's asking about. Once all three are answered, shows the
/// computed starting level.
class FlexibilityStep extends ConsumerWidget {
  const FlexibilityStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final profile = ref.watch(onboardingProfileProvider);
    final controller = ref.read(onboardingProfileProvider.notifier);
    final level = calcFlexibilityLevel(profile.flexAnswers);
    final allAnswered = profile.flexAnswers.every((answer) => answer != null);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < flexibilityQuestions.length; i++) ...[
          if (i > 0) 22.verticalSpace,
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppThumb(
                size: AppThumbSize.large,
                child: StretchFigure(
                  pose: flexibilityQuestions[i].pose,
                  showGround: false,
                ),
              ),
              12.horizontalSpace,
              Expanded(
                child: Text(
                  flexibilityQuestions[i].question,
                  style: AppTextStyle.titleSmall,
                ),
              ),
            ],
          ),
          10.verticalSpace,
          for (final option in flexibilityQuestions[i].options) ...[
            AppOptionTile(
              title: option.label,
              isSelected: profile.flexAnswers[i] == option.score,
              onTap: () => controller.setFlexAnswer(i, option.score),
            ),
            8.verticalSpace,
          ],
        ],
        if (allAnswered) ...[
          10.verticalSpace,
          AppNote(
            tone: AppTone.accent,
            title: 'Starting level: ${flexibilityLevelLabels[level]}',
            message:
                'You can retake this anytime from Progress as you loosen up.',
          ),
        ] else ...[
          6.verticalSpace,
          Text(
            'Answer all three for a starting level.',
            style: AppTextStyle.meta.copyWith(color: colors.ink3),
          ),
        ],
      ],
    );
  }
}
