import 'package:flutter/material.dart';

import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:fitness_app/core/theme/theme.dart';
import 'package:fitness_app/core/utils/greeting.dart';
import 'package:fitness_app/core/widgets/widgets.dart';
import 'package:fitness_app/features/get_ready/get_ready_screen.dart';
import 'package:fitness_app/features/home/models/today_plan.dart';
import 'package:fitness_app/features/home/widgets/today_plan_card.dart';
import 'package:fitness_app/features/routine_detail/routine_detail_screen.dart';

/// Matches the prototype's `screens.today`: greeting + streak, an optional
/// paused-session banner, today's plan, quick picks and the week strip.
class TodayView extends StatelessWidget {
  const TodayView({super.key, required this.firstName});

  final String firstName;

  void _notBuiltYet(BuildContext context) =>
      AppSnackBar.show(context, "That screen isn't built yet.");

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final now = DateTime.now();

    return ListView(
      padding: AppInsets.page,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    friendlyDate(now),
                    style: AppTextStyle.eyebrow.copyWith(color: colors.ink3),
                  ),
                  4.verticalSpace,
                  Text(
                    '${greetingForHour(now.hour)}, $firstName',
                    style: AppTextStyle.headline,
                  ),
                ],
              ),
            ),
            8.horizontalSpace,
            const AppStreakBadge(days: TodayDemoData.currentStreakDays),
          ],
        ),
        18.verticalSpace,
        AppResumeBanner(
          title: 'Morning reset',
          subtitle: 'Stretch 2 of 5: ${TodayDemoData.pausedSession.name}',
          thumbnail: AppThumb(
            isOnDark: true,
            child: StretchFigure(pose: TodayDemoData.pausedSession.pose),
          ),
          onResume: () => _notBuiltYet(context),
        ),
        18.verticalSpace,
        TodayPlanCard(
          plan: TodayDemoData.todaysPlan,
          onStart: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => GetReadyScreen(plan: TodayDemoData.todaysPlan),
            ),
          ),
          onSeeStretches: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) =>
                  RoutineDetailScreen(routine: TodayDemoData.todaysPlan),
            ),
          ),
        ),
        24.verticalSpace,
        Text('Quick picks', style: AppTextStyle.sectionTitle),
        10.verticalSpace,
        for (var i = 0; i < TodayDemoData.quickPicks.length; i += 2) ...[
          if (i > 0) 10.verticalSpace,
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _QuickPickTile(routine: TodayDemoData.quickPicks[i]),
              ),
              10.horizontalSpace,
              Expanded(
                child: i + 1 < TodayDemoData.quickPicks.length
                    ? _QuickPickTile(
                        routine: TodayDemoData.quickPicks[i + 1],
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ],
        24.verticalSpace,
        Text('This week', style: AppTextStyle.sectionTitle),
        10.verticalSpace,
        AppCard(child: AppWeekStrip(days: TodayDemoData.weekStrip(now))),
      ],
    );
  }
}

/// A single "Quick picks" grid cell. Left to size itself (no
/// [IntrinsicHeight]/stretch pairing with its neighbor): that combination
/// measures a `Text` at the row's full width before the `Expanded` above
/// squeezes it to half width, so a longer title wraps to an extra line the
/// box was never sized for and overflows at the bottom.
class _QuickPickTile extends StatelessWidget {
  const _QuickPickTile({required this.routine});

  final RoutineSummary routine;

  @override
  Widget build(BuildContext context) => AppTileCard(
    title: routine.name,
    meta: '${routine.minutes} min',
    thumbnail: AppThumb(child: StretchFigure(pose: routine.stretches.first.pose)),
    onTap: () => Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => RoutineDetailScreen(routine: routine)),
    ),
  );
}
