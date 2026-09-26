import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:fitness_app/core/widgets/widgets.dart';
import 'package:fitness_app/features/onboarding_setup/providers/onboarding_profile_provider.dart';

const List<String> _safetyReasons = [
  'Stretch to a gentle pull, never sharp pain — back off if anything stings '
      'or feels wrong.',
  "Skip anything that touches an area you've flagged as recently injured "
      'or surgical.',
  "If you're pregnant or have a medical condition, check with a doctor "
      'before starting.',
];

/// Step 9 — required safety acknowledgement before the plan is built.
class SafetyStep extends ConsumerWidget {
  const SafetyStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(onboardingProfileProvider);
    final controller = ref.read(onboardingProfileProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const AppReasonList(items: _safetyReasons),
        20.verticalSpace,
        AppOptionTile(
          title: 'I understand and will stretch safely',
          isSelected: profile.safetyAcknowledged,
          shape: AppSelectionShape.checkbox,
          onTap: () =>
              controller.setSafetyAcknowledged(!profile.safetyAcknowledged),
        ),
      ],
    );
  }
}
