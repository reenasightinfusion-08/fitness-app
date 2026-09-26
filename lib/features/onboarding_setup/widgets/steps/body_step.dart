import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:fitness_app/core/utils/app_validators.dart';
import 'package:fitness_app/core/widgets/widgets.dart';
import 'package:fitness_app/features/onboarding_setup/providers/onboarding_profile_provider.dart';

/// Step 1 — optional height (cm) and weight (kg). Entirely skippable; the
/// wizard shell clears both fields when "Skip" is tapped.
class BodyStep extends ConsumerWidget {
  const BodyStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(onboardingProfileProvider);
    final controller = ref.read(onboardingProfileProvider.notifier);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: AppTextField(
            label: 'Height',
            hint: 'cm',
            isOptional: true,
            initialValue: profile.heightCm,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.next,
            validator: AppValidators.optionalNumber(min: 100, max: 230),
            onChanged: controller.setHeightCm,
          ),
        ),
        14.horizontalSpace,
        Expanded(
          child: AppTextField(
            label: 'Weight',
            hint: 'kg',
            isOptional: true,
            initialValue: profile.weightKg,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.done,
            validator: AppValidators.optionalNumber(min: 30, max: 250),
            onChanged: controller.setWeightKg,
          ),
        ),
      ],
    );
  }
}
