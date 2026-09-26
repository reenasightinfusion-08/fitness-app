import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:fitness_app/core/widgets/widgets.dart';
import 'package:fitness_app/features/onboarding_setup/models/onboarding_options.dart';
import 'package:fitness_app/features/onboarding_setup/providers/onboarding_profile_provider.dart';

/// Step 6 — what's on hand at home. "Bodyweight only" is exclusive with
/// every other chip, same as the prototype.
class EquipmentStep extends ConsumerWidget {
  const EquipmentStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(onboardingProfileProvider);
    final controller = ref.read(onboardingProfileProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppChipGroup(
          children: [
            for (final entry in equipmentLabels.entries)
              AppChip(
                label: entry.value,
                isSelected: profile.equipment.contains(entry.key),
                onTap: () => controller.toggleEquipment(entry.key),
              ),
          ],
        ),
        16.verticalSpace,
        AppOptionTile(
          title: 'Nothing, bodyweight only',
          isSelected: profile.equipmentNone,
          shape: AppSelectionShape.checkbox,
          onTap: () => controller.setEquipmentNone(!profile.equipmentNone),
        ),
      ],
    );
  }
}
