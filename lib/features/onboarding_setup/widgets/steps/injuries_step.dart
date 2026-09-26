import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:fitness_app/core/theme/theme.dart';
import 'package:fitness_app/core/widgets/widgets.dart';
import 'package:fitness_app/features/onboarding_setup/models/onboarding_options.dart';
import 'package:fitness_app/features/onboarding_setup/models/onboarding_profile.dart';
import 'package:fitness_app/features/onboarding_setup/providers/onboarding_profile_provider.dart';

const Map<InjurySeverity, String> _severityLabels = {
  InjurySeverity.mild: 'Mild',
  InjurySeverity.moderate: 'Moderate',
  InjurySeverity.serious: 'Serious',
};

/// Step 5 — yes/no situational toggles, plus per-area severity for any
/// injury area the person flags.
class InjuriesStep extends ConsumerWidget {
  const InjuriesStep({super.key});

  bool _flagValue(OnboardingProfile profile, String id) => switch (id) {
    'noKneel' => profile.noKneel,
    'noFloor' => profile.noFloor,
    'surgery' => profile.hadRecentSurgery,
    'pregnant' => profile.isPregnant,
    _ => false,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final profile = ref.watch(onboardingProfileProvider);
    final controller = ref.read(onboardingProfileProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppCard(
          variant: AppCardVariant.list,
          child: Column(
            children: [
              for (var i = 0; i < injuryToggles.length; i++)
                AppSettingRow(
                  title: injuryToggles[i].label,
                  showDivider: i < injuryToggles.length - 1,
                  trailing: AppSwitch(
                    value: _flagValue(profile, injuryToggles[i].id),
                    onChanged: (_) =>
                        controller.toggleInjuryFlag(injuryToggles[i].id),
                  ),
                ),
            ],
          ),
        ),
        20.verticalSpace,
        AppFieldLabel(text: 'Any areas that flare up?', isOptional: true),
        8.verticalSpace,
        AppChipGroup(
          children: [
            for (final entry in injuryAreaLabels.entries)
              AppChip(
                label: entry.value,
                isSelected: profile.injurySeverity.containsKey(entry.key),
                onTap: () => profile.injurySeverity.containsKey(entry.key)
                    ? controller.clearInjurySeverity(entry.key)
                    : controller.setInjurySeverity(
                        entry.key,
                        InjurySeverity.mild,
                      ),
              ),
          ],
        ),
        for (final entry in profile.injurySeverity.entries) ...[
          16.verticalSpace,
          Text(
            'How bad is the ${injuryAreaLabels[entry.key] ?? entry.key}?',
            style: AppTextStyle.titleSmall,
          ),
          8.verticalSpace,
          AppSegmentedControl<InjurySeverity>(
            segments: [
              for (final severity in InjurySeverity.values)
                AppSegmentModel(
                  value: severity,
                  label: _severityLabels[severity]!,
                ),
            ],
            value: entry.value,
            onChanged: (severity) =>
                controller.setInjurySeverity(entry.key, severity),
          ),
          if (entry.value == InjurySeverity.serious) ...[
            8.verticalSpace,
            AppNote(
              tone: AppTone.warm,
              message:
                  "We'll keep this area's stretches very gentle and "
                  'suggest checking with a professional first.',
            ),
          ],
        ],
        if (profile.injurySeverity.isEmpty) ...[
          8.verticalSpace,
          Text(
            'Nothing selected — skip if nothing applies.',
            style: AppTextStyle.meta.copyWith(color: colors.ink3),
          ),
        ],
      ],
    );
  }
}
