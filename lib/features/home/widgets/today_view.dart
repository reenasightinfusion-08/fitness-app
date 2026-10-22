import 'package:fitness_app/core/ads/ad_service.dart';
import 'package:fitness_app/core/ads/ad_slot.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fitness_app/core/providers/providers.dart';
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
import 'package:fitness_app/features/progress/providers/progress_stats_provider.dart';
import 'package:fitness_app/features/routine_detail/routine_detail_screen.dart';
import 'package:fitness_app/features/session_player/session_player_screen.dart';
import 'package:fitness_app/services/paused_session_cache.dart';
import 'package:fitness_app/services/video_background_service.dart';

/// Full container shimmer placeholder for a single Quick Pick tile card.
class QuickPickTileShimmer extends StatelessWidget {
  const QuickPickTileShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Material(
      color: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: AppBorderRadius.xxl,
        side: BorderSide(color: colors.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: EdgeInsets.all(12.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail square skeleton (matches AppThumb 48x48)
            AppShimmer.box(width: 50.r, height: 50.r, borderRadius: 14.r),
            8.verticalSpace,
            const Spacer(),

            // Title text line skeleton
            AppShimmer.box(width: 110.w, height: 18.h, borderRadius: 4.r),
            6.verticalSpace,

            // Duration meta text line skeleton ("2 min 30 sec")
            AppShimmer.box(width: 70.w, height: 14.h, borderRadius: 4.r),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}

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
    final stats = ref.watch(progressStatsProvider);
    final streakDays = stats.streakDays;
    final planActive = ref.watch(todaysPlanActiveProvider).valueOrNull;
    final pausedUserAsync = ref.watch(pausedUserRoutinesProvider);
    final firstName = profile.name.isEmpty ? 'Runner' : profile.name;
    final now = DateTime.now();

    final size = MediaQuery.sizeOf(context);
    final isTablet = size.width >= 600;

    final dateStyle = AppTextStyle.eyebrow.copyWith(
      color: colors.ink3,
      fontSize: isTablet ? 12.0 : null,
    );
    final greetingStyle = AppTextStyle.headline.copyWith(
      fontSize: isTablet ? 28.0 : null,
    );

    return ListView(
      padding: isTablet
          ? const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0)
          : AppInsets.page,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(friendlyDate(now), style: dateStyle),
                  (isTablet ? 6.0 : 4.0).verticalSpace,
                  Text(
                    '${greetingForHour(now.hour)}, $firstName',
                    style: greetingStyle,
                  ),
                ],
              ),
            ),
            (isTablet ? 16.0 : 8.0).horizontalSpace,
            AppStreakBadge(days: streakDays),
          ],
        ),
        (isTablet ? 22.0 : 18.0).verticalSpace,
        pausedUserAsync.when(
          data: (pausedUser) {
            final paused = pausedUser.isNotEmpty ? pausedUser.first : null;
            if (paused == null) return const SizedBox.shrink();
            return Column(
              children: [
                ResumeRoutineBanner(active: paused),
                18.verticalSpace,
              ],
            );
          },
          loading: () {
            if (!PausedSessionCache.hasPausedRoutine) {
              return const SizedBox.shrink();
            }
            return Column(
              children: [const ResumeRoutineBannerShimmer(), 18.verticalSpace],
            );
          },
          error: (error, stack) => const SizedBox.shrink(),
        ),
        planAsync.when(
          data: (todaysPlan) => TodayPlanCard(
            plan: todaysPlan.routine,
            isCompleted: todaysPlan.completedToday,
            resumeFromStretch:
                planActive != null && planActive.completedStretch > 0
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
                : () {
                    VideoBackgroundService.preloadUrls(
                      planActive.routine.stretches.map(
                        (s) => s.model?.videoUrl,
                      ),
                    );
                    Navigator.of(context).push(
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
                    );
                  },
            onRestart: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) =>
                    GetReadyScreen(plan: todaysPlan.routine, source: 'plan'),
              ),
            ),
            onSeeStretches: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) =>
                    RoutineDetailScreen(routine: todaysPlan.routine),
              ),
            ),
          ),
          loading: () => const TodayPlanCardShimmer(),
          error: (error, stack) => TodaysPlanErrorCard(error: error),
        ),
        (isTablet ? 22.0 : 18.0).verticalSpace,
        const AdNative(small: false),
        (isTablet ? 22.0 : 18.0).verticalSpace,
        Text(
          'Quick picks',
          style: AppTextStyle.sectionTitle.copyWith(
            fontSize: isTablet ? 20.0 : null,
          ),
        ),
        (isTablet ? 14.0 : 10.0).verticalSpace,
        routinesAsync.when(
          data: (routines) {
            if (routines.isEmpty) {
              return const AppEmptyState(
                icon: Icons.inbox_outlined,
                title: 'No routines yet',
                message: 'New routines will show up here.',
              );
            }
            return Column(
              children: [
                for (var i = 0; i < routines.length; i += 2) ...[
                  if (i > 0) (isTablet ? 14.0 : 10.0).verticalSpace,
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(child: _QuickPickTile(routine: routines[i])),
                        (isTablet ? 14.0 : 10.0).horizontalSpace,
                        Expanded(
                          child: i + 1 < routines.length
                              ? _QuickPickTile(routine: routines[i + 1])
                              : const SizedBox.shrink(),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            );
          },
          loading: () => Column(
            children: [
              for (var i = 0; i < 2; i++) ...[
                if (i > 0) (isTablet ? 14.0 : 10.0).verticalSpace,
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Expanded(child: QuickPickTileShimmer()),
                      (isTablet ? 14.0 : 10.0).horizontalSpace,
                      const Expanded(child: QuickPickTileShimmer()),
                    ],
                  ),
                ),
              ],
            ],
          ),
          error: (err, stack) => AppEmptyState(
            icon: Icons.cloud_off_rounded,
            title: "Couldn't load routines",
            message: 'Check your connection and try again.',
            actionLabel: 'Try again',
            onAction: () => ref.invalidate(routinesProvider),
          ),
        ),
        (isTablet ? 22.0 : 18.0).verticalSpace,
        const AdNative(small: true),
        (isTablet ? 22.0 : 18.0).verticalSpace,
        Text(
          'This week',
          style: AppTextStyle.sectionTitle.copyWith(
            fontSize: isTablet ? 18.0 : null,
          ),
        ),
        (isTablet ? 10.0 : 10.0).verticalSpace,
        AppCard(
          padding: EdgeInsets.symmetric(
            horizontal: isTablet ? 16.0 : 16.r,
            vertical: isTablet ? 12.0 : 16.r,
          ),
          child: AppWeekStrip(days: stats.weekStrip()),
        ),
      ],
    );
  }
}

/// Skeleton shimmer placeholder matching the paused session banner structure.
class ResumeRoutineBannerShimmer extends StatelessWidget {
  const ResumeRoutineBannerShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: EdgeInsets.all(14.r),
      decoration: BoxDecoration(
        color: colors.playerBg,
        borderRadius: AppBorderRadius.xxl,
      ),
      child: Row(
        children: [
          // Thumbnail square skeleton (matches AppThumb medium 48x48)
          AppShimmer.box(width: 48.r, height: 48.r, borderRadius: 14.r),
          12.horizontalSpace,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Eyebrow skeleton ("Paused session")
                AppShimmer.box(width: 90.w, height: 14.h, borderRadius: 4.r),
                7.verticalSpace,
                // Title skeleton (Routine name)
                AppShimmer.box(width: 145.w, height: 18.h, borderRadius: 4.r),
                7.verticalSpace,
                // Subtitle skeleton ("Stretch X of Y")
                AppShimmer.box(width: 115.w, height: 14.h, borderRadius: 4.r),
              ],
            ),
          ),
          12.horizontalSpace,
          // Resume button skeleton (matches AppButton small pill)
          AppShimmer.box(width: 88.w, height: 36.h, borderRadius: 100.r),
        ],
      ),
    );
  }
}

/// The "Paused session" card for a routine the user began and didn't finish.
/// Resuming jumps straight into the player at the stretch they stopped at.
class ResumeRoutineBanner extends StatefulWidget {
  const ResumeRoutineBanner({super.key, required this.active});

  final ActiveRoutineModel active;

  @override
  State<ResumeRoutineBanner> createState() => _ResumeRoutineBannerState();
}

class _ResumeRoutineBannerState extends State<ResumeRoutineBanner> {
  @override
  void initState() {
    super.initState();
    _preload();
  }

  @override
  void didUpdateWidget(covariant ResumeRoutineBanner oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.active != widget.active) {
      _preload();
    }
  }

  void _preload() {
    VideoBackgroundService.preloadUrls(
      widget.active.routine.stretches.map((s) => s.model?.videoUrl),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final isTablet = size.width >= 600;
    final active = widget.active;
    final next = active.nextStretch;
    final total = active.routine.stretches.length;
    return AppResumeBanner(
      title: active.routine.name,
      subtitle: next == null
          ? '$total stretches'
          : 'Stretch ${active.completedStretch + 1} of $total: ${next.name}',
      thumbnail: next == null
          ? null
          : StretchThumbnail(
              stretch: next,
              isOnDark: true,
              size: isTablet ? AppThumbSize.large : AppThumbSize.medium,
            ),
      onResume: () {
        Navigator.of(context).push(
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
        );
      },
    );
  }
}

/// A single "Quick picks" grid cell. Displays routine data immediately and
/// loads stretch thumbnail with smooth fallback to photo or placeholder.
class _QuickPickTile extends StatelessWidget {
  const _QuickPickTile({required this.routine});

  final RoutineSummary routine;

  @override
  Widget build(BuildContext context) {
    final firstStretch = routine.stretches.isNotEmpty
        ? routine.stretches.first
        : null;

    final Widget thumbnailWidget = firstStretch != null
        ? StretchThumbnail(
            stretch: firstStretch,
            size: AppThumbSize.medium,
          )
        : const AppThumb(
            size: AppThumbSize.medium,
            child: StretchPlaceholder(),
          );

    return AppTileCard(
      title: routine.name,
      meta: routine.durationText,
      thumbnail: thumbnailWidget,
      onTap: () {
        void navigate() {
          if (!context.mounted) return;
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => RoutineDetailScreen(routine: routine),
            ),
          );
        }

        AdService.maybeShowInterstitial(action: 'routine', onClosed: navigate);
      },
    );
  }
}
