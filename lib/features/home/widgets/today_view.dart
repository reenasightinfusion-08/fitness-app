import 'dart:typed_data';
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
import 'package:fitness_app/services/video_frame_service.dart';

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
            AppStreakBadge(days: streakDays),
          ],
        ),
        18.verticalSpace,
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
              children: [
                const ResumeRoutineBannerShimmer(),
                18.verticalSpace,
              ],
            ); 
          },
          error: (error, stack) => const SizedBox.shrink(),
        ),
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
                : () {
                    VideoBackgroundService.preloadUrls(
                      planActive.routine.stretches.map((s) => s.model?.videoUrl),
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
                builder: (_) => RoutineDetailScreen(routine: todaysPlan.routine),
              ),
            ),
          ),
          loading: () => const TodayPlanCardShimmer(),
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
          loading: () => Column(
            children: [
              for (var i = 0; i < 2; i++) ...[
                if (i > 0) 10.verticalSpace,
                const IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(child: QuickPickTileShimmer()),
                      SizedBox(width: 10),
                      Expanded(child: QuickPickTileShimmer()),
                    ],
                  ),
                ),
              ],
            ],
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
        AppCard(child: AppWeekStrip(days: stats.weekStrip())),
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
          : StretchThumbnail(stretch: next, isOnDark: true),
      onResume: () {
        _preload();
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

/// A single "Quick picks" grid cell. Displays full container shimmer until
/// both routine data and stretch thumbnail frame are available.
class _QuickPickTile extends StatefulWidget {
  const _QuickPickTile({required this.routine});

  final RoutineSummary routine;

  @override
  State<_QuickPickTile> createState() => _QuickPickTileState();
}

class _QuickPickTileState extends State<_QuickPickTile> {
  late Future<Uint8List?> _frameFuture;

  @override
  void initState() {
    super.initState();
    _initFrameFuture();
  }

  @override
  void didUpdateWidget(covariant _QuickPickTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.routine != widget.routine) {
      _initFrameFuture();
    }
  }

  void _initFrameFuture() {
    final firstStretch = widget.routine.stretches.isNotEmpty
        ? widget.routine.stretches.first
        : null;
    final videoUrl = firstStretch?.model?.videoUrl;
    if (videoUrl != null && videoUrl.trim().isNotEmpty) {
      _frameFuture = VideoFrameService.frameAt(
        videoUrl,
        timeMs: VideoFrameService.midpointMs(
          firstStretch?.model?.defaultHoldSeconds ?? 30,
        ),
      );
    } else {
      _frameFuture = Future.value(null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List?>(
      future: _frameFuture,
      builder: (context, snapshot) {
        // Show full container shimmer until data and image frame finish loading
        if (snapshot.connectionState != ConnectionState.done) {
          return const QuickPickTileShimmer();
        }
        return _buildTileContent(context, snapshot.data);
      },
    );
  }

  Widget _buildTileContent(BuildContext context, Uint8List? frameBytes) {
    final routine = widget.routine;
    final firstStretch =
        routine.stretches.isNotEmpty ? routine.stretches.first : null;
    final thumbUrl = firstStretch?.model?.thumbnailUrl;
    final hasThumb = thumbUrl != null && thumbUrl.trim().isNotEmpty;

    Widget thumbnailWidget;
    if (frameBytes != null) {
      thumbnailWidget = Image.memory(
        frameBytes,
        fit: BoxFit.cover,
        gaplessPlayback: true,
      );
    } else if (hasThumb) {
      thumbnailWidget = Image.network(
        thumbUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => StretchFigure(
          pose: firstStretch?.pose ?? StretchPoses.neutral,
        ),
      );
    } else {
      thumbnailWidget = StretchFigure(
        pose: firstStretch?.pose ?? StretchPoses.neutral,
      );
    }

    return AppTileCard(
      title: routine.name,
      meta: routine.durationText,
      thumbnail: AppThumb(child: thumbnailWidget),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => RoutineDetailScreen(routine: routine),
        ),
      ),
    );
  }
}
