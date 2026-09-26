import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:fitness_app/core/widgets/widgets.dart';
import 'package:fitness_app/features/onboarding_setup/models/onboarding_options.dart';
import 'package:fitness_app/features/onboarding_setup/providers/onboarding_profile_provider.dart';

/// Step 2 — a normal day (single choice) plus optional sports chips.
class LifestyleStep extends ConsumerWidget {
  const LifestyleStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(onboardingProfileProvider);
    final controller = ref.read(onboardingProfileProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final option in lifestyleOptions) ...[
          AppOptionTile(
            title: option.label,
            subtitle: option.subtitle,
            isSelected: profile.lifestyle == option.id,
            onTap: () => controller.setLifestyle(option.id),
          ),
          10.verticalSpace,
        ],
        10.verticalSpace,
        AppFieldLabel(text: 'Sports you play', isOptional: true),
        8.verticalSpace,
        AppChipGroup(
          children: [
            for (final sport in sportsOptions)
              AppChip(
                label: sport,
                isSelected: profile.sports.contains(sport),
                onTap: () => controller.toggleSport(sport),
              ),
          ],
        ),
      ],
    );
  }
}
