import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:fitness_app/core/providers/providers.dart';
import 'package:fitness_app/core/theme/theme.dart';
import 'package:fitness_app/core/utils/greeting.dart';
import 'package:fitness_app/core/widgets/widgets.dart';
import 'package:fitness_app/features/home/models/active_routine_model.dart';
import 'package:fitness_app/features/onboarding_setup/providers/onboarding_profile_provider.dart';
import 'package:fitness_app/features/profile/models/session_settings.dart';
import 'package:fitness_app/features/profile/providers/session_settings_provider.dart';
import 'package:fitness_app/features/onboarding_setup/models/onboarding_profile.dart';
import 'package:fitness_app/features/progress/flexibility_check_screen.dart';
import 'package:fitness_app/features/progress/providers/progress_stats_provider.dart';
import 'package:fitness_app/features/routine_detail/routine_detail_screen.dart';

const _monthNames = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];

/// Matches the prototype's `screens.progress`: streak/minutes/session
/// stats, a month calendar, where-you've-stretched body map, flexibility
/// level and recent history.
class ProgressView extends ConsumerWidget {
  const ProgressView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final stats = ref.watch(progressStatsProvider);
    final now = stats.today;
    final dayStartHour = ref.watch(sessionSettingsProvider).dayStartHour;
    final historyAsync = ref.watch(routineHistoryProvider);

    // The areas marked tight or sore during setup — same source the
    // prototype's body map reads from (`acct().profile.pain`).
    final profile = ref.watch(onboardingProfileProvider);
    final markedAreas = profile.painAreas;
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
                value: '${stats.streakDays}',
                label: 'day streak',
              ),
            ),
            8.horizontalSpace,
            Expanded(
              child: AppStatTile(
                value: '${stats.minutesThisWeek}',
                label: 'min this week',
              ),
            ),
            8.horizontalSpace,
            Expanded(
              child: AppStatTile(
                value: '${stats.totalSessions}',
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
                      _monthNames[now.month - 1],
                      style: AppTextStyle.titleMedium,
                    ),
                  ),
                  Text(
                    'Days start at ${dayStartHourLabel(dayStartHour)}',
                    style: AppTextStyle.meta.copyWith(color: colors.ink2),
                  ),
                ],
              ),
              12.verticalSpace,
              AppCalendarGrid(
                leadingBlankDays: DateTime(now.year, now.month, 1).weekday - 1,
                dayCount: DateUtils.getDaysInMonth(now.year, now.month),
                completedDays: stats.completedDaysThisMonth,
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
                      flexibilityLevelLabels[calcFlexibilityLevel(
                        profile.flexAnswers,
                      )],
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
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const FlexibilityCheckScreen(),
                  ),
                ),
              ),
            ],
          ),
        ),
        24.verticalSpace,
        Text('History', style: AppTextStyle.sectionTitle),
        10.verticalSpace,
        historyAsync.when(
          data: (history) => _HistoryList(history: history),
          loading: () => Padding(
            padding: EdgeInsets.symmetric(vertical: 32.h),
            child: const Center(child: AppLoader()),
          ),
          error: (error, stack) => const AppEmptyState(
            icon: Icons.cloud_off_rounded,
            title: "Couldn't load history",
            message: 'Check your connection and try again.',
          ),
        ),
      ],
    );
  }
}

/// Scrollable list of completed routines, newest first. Falls back to an empty
/// state when the user hasn't finished a routine yet (new accounts, demo mode).
class _HistoryList extends StatelessWidget {
  const _HistoryList({required this.history});

  final List<ActiveRoutineModel> history;

  @override
  Widget build(BuildContext context) {
    if (history.isEmpty) {
      return const AppEmptyState(
        icon: Icons.history_rounded,
        title: 'No sessions yet',
        message: 'Your finished sessions show up here.',
      );
    }
    return AppCard(
      variant: AppCardVariant.list,
      child: Column(
        children: [
          for (final record in history)
            AppSettingRow(
              title: record.routine.name,
              subtitle:
                  '${record.completedAt == null ? '' : friendlyDate(record.completedAt!) + ' · '}'
                  '${record.routine.stretches.length} stretches',
              trailing: AppTag(label: '${record.routine.minutes} min'),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) =>
                      RoutineDetailScreen(routine: record.routine),
                ),
              ),
              showDivider: record != history.last,
            ),
        ],
      ),
    );
  }
}
