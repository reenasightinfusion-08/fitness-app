import 'package:fitness_app/core/providers/providers.dart';
import 'package:fitness_app/features/session_player/session_player_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fitness_app/core/theme/theme.dart';
import 'package:fitness_app/core/utils/greeting.dart';
import 'package:fitness_app/core/widgets/widgets.dart';
import 'package:fitness_app/features/get_ready/get_ready_screen.dart';
import 'package:fitness_app/features/home/models/active_routine_model.dart';
import 'package:fitness_app/features/home/models/today_plan.dart';
import 'package:fitness_app/features/home/widgets/stretch_thumbnail.dart';
import 'package:fitness_app/features/home/widgets/today_plan_card.dart';
import 'package:fitness_app/features/home/widgets/todays_plan_error_card.dart';
import 'package:fitness_app/features/onboarding_setup/providers/onboarding_profile_provider.dart';
import 'package:fitness_app/features/routine_detail/routine_detail_screen.dart';

/// Matches the prototype's `screens.today`: greeting + streak, an optional
/// paused-session banner, today's plan, quick picks and the week strip.
class TodayView extends ConsumerWidget {
  const TodayView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final profile = ref.watch(onboardingProfileProvider);
    final routinesAsync = ref.watch(routinesProvider);
    final planAsync = ref.watch(todaysPlanProvider);
    final planActive = ref.watch(todaysPlanActiveProvider).valueOrNull;
    final pausedUser = ref.watch(pausedUserRoutinesProvider).valueOrNull ?? const [];
    final paused = pausedUser.isNotEmpty ? pausedUser.first : null;
    final firstName = profile.name.isEmpty ? 'Runner' : profile.name;
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
        if (paused != null) ...[
          ResumeRoutineBanner(active: paused),
          18.verticalSpace,
        ],
        planAsync.when(
          data: (todaysPlan) => TodayPlanCard(
            plan: todaysPlan.routine,
            isCompleted: todaysPlan.completedToday,
            resumeFromStretch: planActive != null && planActive.completedStretch > 0
                ? planActive.completedStretch
                : null,
            onStart: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) =>
                    GetReadyScreen(plan: todaysPlan.routine, source: 'plan'),
              ),
            ),
            onResume: planActive == null
                ? null
                : () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => SessionPlayerScreen(
                        plan: planActive.routine,
                        startStretchIndex: planActive.completedStretch,
                        onProgress: trackProgress(
                          ProviderScope.containerOf(context),
                          planActive,
                        ),
                      ),
                    ),
                  ),
            onRestart: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) =>
                    GetReadyScreen(plan: todaysPlan.routine, source: 'plan'),
              ),
            ),
            onSeeStretches: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => RoutineDetailScreen(routine: todaysPlan.routine),
              ),
            ),
          ),
          loading: () => AppCard(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 32.h),
              child: const Center(child: AppLoader()),
            ),
          ),
          error: (error, stack) => TodaysPlanErrorCard(error: error),
        ),
        24.verticalSpace,
        Text('Quick picks', style: AppTextStyle.sectionTitle),
        10.verticalSpace,
        routinesAsync.when(
          data: (routines) {
            final quickPicks =
                routines.isNotEmpty ? routines : TodayDemoData.quickPicks;
            return Column(
              children: [
                for (var i = 0; i < quickPicks.length; i += 2) ...[
                  if (i > 0) 10.verticalSpace,
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: _QuickPickTile(routine: quickPicks[i]),
                        ),
                        10.horizontalSpace,
                        Expanded(
                          child: i + 1 < quickPicks.length
                              ? _QuickPickTile(routine: quickPicks[i + 1])
                              : const SizedBox.shrink(),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            );
          },
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: CircularProgressIndicator(),
            ),
          ),
          error: (err, stack) {
            final quickPicks = TodayDemoData.quickPicks;
            return Column(
              children: [
                for (var i = 0; i < quickPicks.length; i += 2) ...[
                  if (i > 0) 10.verticalSpace,
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _QuickPickTile(routine: quickPicks[i]),
                      ),
                      10.horizontalSpace,
                      Expanded(
                        child: i + 1 < quickPicks.length
                            ? _QuickPickTile(routine: quickPicks[i + 1])
                            : const SizedBox.shrink(),
                      ),
                    ],
                  ),
                ],
              ],
            );
          },
        ),
        24.verticalSpace,
        Text('This week', style: AppTextStyle.sectionTitle),
        10.verticalSpace,
        AppCard(child: AppWeekStrip(days: TodayDemoData.weekStrip(now))),
      ],
    );
  }
}

/// The "Paused session" card for a routine the user began and didn't finish.
/// Resuming jumps straight into the player at the stretch they stopped at.
class ResumeRoutineBanner extends StatelessWidget {
  const ResumeRoutineBanner({super.key, required this.active});

  final ActiveRoutineModel active;

  @override
  Widget build(BuildContext context) {
    final next = active.nextStretch;
    final total = active.routine.stretches.length;
    return AppResumeBanner(
      title: active.routine.name,
      subtitle: next == null
          ? '$total stretches'
          : 'Stretch ${active.completedStretch + 1} of $total: ${next.name}',
      thumbnail: next == null
          ? null
          : StretchThumbnail(stretch: next, isOnDark: true),
      onResume: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => SessionPlayerScreen(
            plan: active.routine,
            startStretchIndex: active.completedStretch,
            onProgress: trackProgress(
              ProviderScope.containerOf(context),
              active,
            ),
          ),
        ),
      ),
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
  Widget build(BuildContext context) {
    final firstStretch =
        routine.stretches.isNotEmpty ? routine.stretches.first : null;
    final thumbUrl = firstStretch?.model?.thumbnailUrl;
    final hasThumb = thumbUrl != null && thumbUrl.trim().isNotEmpty;

    return AppTileCard(
      title: routine.name,
      meta: routine.durationText,
      thumbnail: AppThumb(
        child: hasThumb
            ? Image.network(
                thumbUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => StretchFigure(
                  pose: firstStretch?.pose ?? StretchPoses.neutral,
                ),
              )
            : StretchFigure(
                pose: firstStretch?.pose ?? StretchPoses.neutral,
              ),
      ),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => RoutineDetailScreen(routine: routine)),
      ),
    );
  }
}
