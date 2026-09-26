import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:fitness_app/core/utils/app_validators.dart';
import 'package:fitness_app/core/widgets/widgets.dart';
import 'package:fitness_app/features/onboarding_setup/models/onboarding_options.dart';
import 'package:fitness_app/features/onboarding_setup/providers/onboarding_profile_provider.dart';

/// Step 0 — first name (required), age (optional), gender (optional chips).
class BasicStep extends ConsumerWidget {
  const BasicStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(onboardingProfileProvider);
    final controller = ref.read(onboardingProfileProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppTextField(
          label: 'First name',
          hint: 'What should we call you?',
          initialValue: profile.name,
          textInputAction: TextInputAction.next,
          validator: AppValidators.required,
          onChanged: controller.setName,
        ),
        14.verticalSpace,
        AppTextField(
          label: 'Age',
          hint: 'Years',
          isOptional: true,
          initialValue: profile.age,
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.done,
          validator: AppValidators.optionalNumber(min: 10, max: 100),
          onChanged: controller.setAge,
        ),
        18.verticalSpace,
        AppFieldLabel(text: 'Gender', isOptional: true),
        8.verticalSpace,
        AppChipGroup(
          children: [
            for (final option in genderOptions)
              AppChip(
                label: option,
                isSelected: profile.gender == option,
                onTap: () => controller.setGender(option),
              ),
          ],
        ),
      ],
    );
  }
}
