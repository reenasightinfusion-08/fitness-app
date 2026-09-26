import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:fitness_app/core/theme/theme.dart';
import 'package:fitness_app/core/widgets/widgets.dart';
import 'package:fitness_app/features/onboarding_setup/models/onboarding_options.dart';
import 'package:fitness_app/features/onboarding_setup/providers/onboarding_profile_provider.dart';

/// Step 3 — pick up to [maxGoalPicks] goals.
class GoalsStep extends ConsumerWidget {
  const GoalsStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final profile = ref.watch(onboardingProfileProvider);
    final controller = ref.read(onboardingProfileProvider.notifier);
    final atCap = profile.goals.length >= maxGoalPicks;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final option in goalOptions) ...[
          AppOptionTile(
            title: option.label,
            isSelected: profile.goals.contains(option.id),
            shape: AppSelectionShape.checkbox,
            onTap: atCap && !profile.goals.contains(option.id)
                ? null
                : () => controller.toggleGoal(option.id),
          ),
          10.verticalSpace,
        ],
        Text(
          '${profile.goals.length}/$maxGoalPicks selected',
          style: AppTextStyle.meta.copyWith(color: colors.ink2),
        ),
      ],
    );
  }
}
