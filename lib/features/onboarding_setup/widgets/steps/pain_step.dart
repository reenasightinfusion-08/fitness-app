import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fitness_app/core/widgets/widgets.dart';
import 'package:fitness_app/features/onboarding_setup/models/onboarding_options.dart';
import 'package:fitness_app/features/onboarding_setup/providers/onboarding_profile_provider.dart';

/// Step 4 — tap the areas that feel tight or sore. The prototype's
/// interactive body-map SVG is simplified to a chip grid here; a hand-drawn
/// tappable silhouette isn't worth the complexity for what's a plain
/// multi-select underneath.
class PainStep extends ConsumerWidget {
  const PainStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(onboardingProfileProvider);
    final controller = ref.read(onboardingProfileProvider.notifier);

    return AppChipGroup(
      children: [
        for (final entry in painAreaLabels.entries)
          AppChip(
            label: entry.value,
            isSelected: profile.painAreas.contains(entry.key),
            onTap: () => controller.togglePainArea(entry.key),
          ),
      ],
    );
  }
}
