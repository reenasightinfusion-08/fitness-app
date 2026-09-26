import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:fitness_app/core/theme/theme.dart';
import 'package:fitness_app/core/utils/greeting.dart';
import 'package:fitness_app/core/widgets/widgets.dart';
import 'package:fitness_app/features/onboarding_setup/providers/onboarding_profile_provider.dart';
import 'package:fitness_app/features/progress/models/progress_data.dart';

/// Matches the prototype's `screens.progress`: streak/minutes/session
/// stats, a month calendar, where-you've-stretched body map, flexibility
/// level and recent history.
class ProgressView extends ConsumerWidget {
  const ProgressView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final now = DateTime.now();
    final sessions = ProgressDemoData.sessions(now);

    // The areas marked tight or sore during setup — same source the
    // prototype's body map reads from (`acct().profile.pain`).
    final markedAreas = ref.watch(onboardingProfileProvider).painAreas;
    final heat = {for (final area in markedAreas) area: 1};

    return ListView(
      padding: AppInsets.page,
      children: [
        Text('Progress', style: AppTextStyle.headline),
        18.verticalSpace,
        Row(
          children: [
            Expanded(
              child: AppStatTile(
                value: '${ProgressDemoData.currentStreakDays}',
                label: 'day streak',
              ),
            ),
            8.horizontalSpace,
            Expanded(
              child: AppStatTile(
                value: '${ProgressDemoData.minutesThisWeek}',
                label: 'min this week',
              ),
            ),
            8.horizontalSpace,
            Expanded(
              child: AppStatTile(
                value: '${ProgressDemoData.totalSessions}',
                label: 'sessions',
              ),
            ),
          ],
        ),
        18.verticalSpace,
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Last 5 weeks',
                      style: AppTextStyle.titleMedium,
                    ),
                  ),
                  Text(
                    'Days start at 5:00 am',
                    style: AppTextStyle.meta.copyWith(color: colors.ink2),
                  ),
                ],
              ),
              12.verticalSpace,
              AppCalendarGrid(
                leadingBlankDays: DateTime(now.year, now.month, 1).weekday - 1,
                dayCount: DateUtils.getDaysInMonth(now.year, now.month),
                completedDays: ProgressDemoData.completedDaysInMonth(now),
                today: now.day,
              ),
            ],
          ),
        ),
        18.verticalSpace,
        AppSectionWrapper(
          title: "Where you've stretched",
          child: AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Marked tight or sore during setup',
                  style: AppTextStyle.meta.copyWith(color: colors.ink2),
                ),
                12.verticalSpace,
                AppBodyHeatMap(heat: heat),
              ],
            ),
          ),
        ),
        18.verticalSpace,
        AppCard(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Flexibility level', style: AppTextStyle.titleMedium),
                    Text(
                      ProgressDemoData.flexibilityLevel,
                      style: AppTextStyle.meta.copyWith(color: colors.ink2),
                    ),
                  ],
                ),
              ),
              10.horizontalSpace,
              AppButton(
                label: 'Retake check',
                variant: AppButtonVariant.secondary,
                size: AppButtonSize.small,
                isExpanded: false,
                onPressed: () => AppSnackBar.show(
                  context,
                  "That screen isn't built yet.",
                ),
              ),
            ],
          ),
        ),
        24.verticalSpace,
        Text('History', style: AppTextStyle.sectionTitle),
        10.verticalSpace,
        if (sessions.isEmpty)
          const AppEmptyState(
            icon: Icons.history_rounded,
            title: 'No sessions yet',
            message: 'Your finished sessions show up here.',
          )
        else
          AppCard(
            variant: AppCardVariant.list,
            child: Column(
              children: [
                for (final session in sessions)
                  AppSettingRow(
                    title: session.title,
                    subtitle:
                        '${friendlyDate(session.date)} · '
                        '${session.stretchCount} stretches',
                    trailing: AppTag(label: '${session.minutes} min'),
                    showDivider: session != sessions.last,
                  ),
              ],
            ),
          ),
      ],
    );
  }
}
