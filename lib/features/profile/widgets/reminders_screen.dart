import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:fitness_app/core/theme/theme.dart';
import 'package:fitness_app/core/widgets/widgets.dart';
import 'package:fitness_app/features/profile/models/reminder.dart';
import 'package:fitness_app/features/profile/providers/reminders_provider.dart';

/// Matches the prototype's `screens.reminders`: one or more push
/// reminders, plus a desk-break nudge that repeats through work hours.
class RemindersScreen extends ConsumerWidget {
  const RemindersScreen({super.key});

  Future<void> _pickTime(
    BuildContext context,
    WidgetRef ref,
    ReminderEntry reminder,
  ) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: reminder.time,
    );
    if (picked != null) {
      ref.read(remindersProvider.notifier).setTime(reminder.id, picked);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final reminders = ref.watch(remindersProvider);
    final desk = ref.watch(deskNudgeProvider);
    final deskNotifier = ref.read(deskNudgeProvider.notifier);

    return Scaffold(
      backgroundColor: colors.ground,
      appBar: AppTopBar(
        title: 'Reminders',
        onBack: () => Navigator.of(context).pop(),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: AppInsets.page,
          children: [
            Text(
              'Reminders arrive as notifications, even when the app is closed.',
              style: AppTextStyle.bodyMedium.copyWith(color: colors.ink2),
            ),
            16.verticalSpace,
            if (reminders.isEmpty) ...[
              AppCard(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 12.h),
                  child: Text(
                    'No reminder set yet',
                    textAlign: TextAlign.center,
                    style: AppTextStyle.bodyMedium.copyWith(color: colors.ink2),
                  ),
                ),
              ),
              12.verticalSpace,
            ],
            for (final reminder in reminders) ...[
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => _pickTime(context, ref, reminder),
                            child: Container(
                              height: 44.h,
                              alignment: Alignment.centerLeft,
                              padding: EdgeInsets.symmetric(horizontal: 12.w),
                              decoration: BoxDecoration(
                                color: colors.surface2,
                                borderRadius: AppBorderRadius.lg,
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.schedule_rounded,
                                    size: 18.r,
                                    color: colors.ink2,
                                  ),
                                  8.horizontalSpace,
                                  Text(
                                    reminder.time.format(context),
                                    style: AppTextStyle.titleSmall,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        12.horizontalSpace,
                        AppSwitch(
                          value: reminder.isOn,
                          onChanged: (_) => ref
                              .read(remindersProvider.notifier)
                              .toggleOn(reminder.id),
                          semanticLabel: 'Reminder on',
                        ),
                      ],
                    ),
                    12.verticalSpace,
                    Wrap(
                      spacing: 6.w,
                      runSpacing: 6.h,
                      children: [
                        for (final weekday in weekdayDisplayOrder)
                          Semantics(
                            label: weekdayFullLabels[weekday],
                            child: AppChip(
                              label: weekdayShortLabels[weekday]!,
                              isSelected: reminder.days.contains(weekday),
                              isCompact: true,
                              showCheck: false,
                              onTap: () => ref
                                  .read(remindersProvider.notifier)
                                  .toggleDay(reminder.id, weekday),
                            ),
                          ),
                      ],
                    ),
                    ...[
                      8.verticalSpace,
                      Align(
                        alignment: Alignment.centerLeft,
                        child: AppButton(
                          label: 'Remove',
                          variant: AppButtonVariant.dangerText,
                          size: AppButtonSize.small,
                          isExpanded: false,
                          onPressed: () => ref
                              .read(remindersProvider.notifier)
                              .remove(reminder.id),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              12.verticalSpace,
            ],
            AppButton(
              label: 'Add a reminder',
              icon: Icons.add_rounded,
              variant: AppButtonVariant.secondary,
              onPressed: () => ref.read(remindersProvider.notifier).add(),
            ),
            20.verticalSpace,
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Desk-break nudges',
                              style: AppTextStyle.titleSmall,
                            ),
                            Text(
                              'A 2-minute stretch prompt during work hours',
                              style: AppTextStyle.meta.copyWith(
                                color: colors.ink2,
                              ),
                            ),
                          ],
                        ),
                      ),
                      AppSwitch(
                        value: desk.isOn,
                        onChanged: deskNotifier.setOn,
                        semanticLabel: 'Desk-break nudges',
                      ),
                    ],
                  ),
                  if (desk.isOn) ...[
                    14.verticalSpace,
                    Text(
                      'Every',
                      style: AppTextStyle.label.copyWith(color: colors.ink2),
                    ),
                    8.verticalSpace,
                    AppSegmentedControl<int>(
                      segments: [
                        for (final minutes in deskNudgeIntervalOptions)
                          AppSegmentModel(value: minutes, label: '$minutes min'),
                      ],
                      value: desk.everyMinutes,
                      onChanged: deskNotifier.setEveryMinutes,
                    ),
                    8.verticalSpace,
                    Text(
                      'Between ${desk.fromLabel} and ${desk.toLabel}, Monday '
                      'to Friday.',
                      style: AppTextStyle.meta.copyWith(color: colors.ink2),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
