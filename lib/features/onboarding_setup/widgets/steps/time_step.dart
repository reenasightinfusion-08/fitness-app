import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:fitness_app/core/theme/theme.dart';
import 'package:fitness_app/core/widgets/widgets.dart';
import 'package:fitness_app/features/onboarding_setup/models/onboarding_options.dart';
import 'package:fitness_app/features/onboarding_setup/models/onboarding_profile.dart';
import 'package:fitness_app/features/onboarding_setup/providers/onboarding_profile_provider.dart';

/// Step 8 — minutes per day, when, and an optional daily reminder.
class TimeStep extends ConsumerWidget {
  const TimeStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(onboardingProfileProvider);
    final controller = ref.read(onboardingProfileProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppFieldLabel(text: 'Minutes per day'),
        8.verticalSpace,
        AppSegmentedControl<int>(
          segments: [
            for (final minutes in minutesPerDayOptions)
              AppSegmentModel(value: minutes, label: '${minutes}m'),
          ],
          value: profile.minutesPerDay,
          onChanged: controller.setMinutesPerDay,
        ),
        20.verticalSpace,
        AppFieldLabel(text: 'When do you usually have time?', isOptional: true),
        8.verticalSpace,
        AppChipGroup(
          children: [
            for (final option in timeOfDayOptions)
              AppChip(
                label: option,
                isSelected: profile.timeOfDay == option,
                onTap: () => controller.setTimeOfDay(option),
              ),
          ],
        ),
        20.verticalSpace,
        AppCard(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Daily reminder', style: AppTextStyle.titleSmall),
                    Text(
                      profile.reminderOn
                          ? _formatTime(profile.reminderTime)
                          : "We won't nudge you",
                      style: AppTextStyle.meta.copyWith(
                        color: context.colors.ink2,
                      ),
                    ),
                  ],
                ),
              ),
              if (profile.reminderOn)
                AppButton(
                  label: _formatTime(profile.reminderTime),
                  variant: AppButtonVariant.secondary,
                  size: AppButtonSize.small,
                  isExpanded: false,
                  onPressed: () => _pickTime(context, controller, profile),
                ),
              12.horizontalSpace,
              AppSwitch(
                value: profile.reminderOn,
                onChanged: controller.setReminderOn,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _pickTime(
    BuildContext context,
    OnboardingProfileController controller,
    OnboardingProfile profile,
  ) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: profile.reminderTime,
    );
    if (picked != null) controller.setReminderTime(picked);
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }
}
