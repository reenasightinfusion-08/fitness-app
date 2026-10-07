import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:fitness_app/core/theme/theme.dart';
import 'package:fitness_app/core/widgets/widgets.dart';
import 'package:fitness_app/features/home/models/today_plan.dart';
import 'package:fitness_app/features/home/widgets/stretch_thumbnail.dart';
import 'package:fitness_app/services/video_frame_service.dart';

/// Full-container shimmer skeleton displayed while Today's Plan data or images are loading.
class TodayPlanCardShimmer extends StatelessWidget {
  const TodayPlanCardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Subtitle / metadata line skeleton ("Today's plan · 9 min 25 sec")
          AppShimmer.box(width: 140.w, height: 14.h, borderRadius: 4.r),
          4.verticalSpace,

          // Routine Title line skeleton ("Full-body flow")
          AppShimmer.box(width: 180.w, height: 26.h, borderRadius: 6.r),
          16.verticalSpace,

          // Stretch Thumbnails Row skeleton (5 thumbnails with 6.w gap)
          Row(
            children: List.generate(
              5,
              (index) => Padding(
                padding: EdgeInsets.only(right: 6.w),
                child: AppShimmer.box(
                  width: 50.r,
                  height: 50.r,
                  borderRadius: 14.r,
                ),
              ),
            ),
          ),
          12.verticalSpace,

          // Tag Pill skeleton ("Full body")
          AppShimmer.box(
            width: 76.w,
            height: 26.h,
            borderRadius: 100.r,
          ),
          16.verticalSpace,

          // Start & See stretches buttons skeleton
          Row(
            children: [
              Expanded(
                child: AppShimmer.box(height: 46.h, borderRadius: 12.r),
              ),
              10.horizontalSpace,
              Expanded(
                child: AppShimmer.box(height: 46.h, borderRadius: 12.r),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// The prototype's `.card.plan`: today's routine name and length, a row of
/// every stretch's photo (scrolls sideways when they don't fit), why-it-fits
/// tags, and Start / See stretches actions.
class TodayPlanCard extends StatefulWidget {
  const TodayPlanCard({
    super.key,
    required this.plan,
    required this.onStart,
    required this.onSeeStretches,
    this.isCompleted = false,
    this.resumeFromStretch,
    this.onResume,
    this.onRestart,
  });

  final RoutineSummary plan;

  /// The user already finished this routine today — the card shows a
  /// "Completed" state with Restart in place of Start.
  final bool isCompleted;

  /// Stretches already done on an in-progress attempt; non-null means the Start
  /// button is replaced with Resume and the subtitle names the next stretch.
  final int? resumeFromStretch;

  final VoidCallback onStart;
  final VoidCallback onSeeStretches;
  final VoidCallback? onResume;
  final VoidCallback? onRestart;

  @override
  State<TodayPlanCard> createState() => _TodayPlanCardState();
}

class _TodayPlanCardState extends State<TodayPlanCard> {
  late Future<List<Uint8List?>> _framesFuture;

  @override
  void initState() {
    super.initState();
    _initFramesFuture();
  }

  @override
  void didUpdateWidget(covariant TodayPlanCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.plan != widget.plan) {
      _initFramesFuture();
    }
  }

  void _initFramesFuture() {
    final futures = widget.plan.stretches.map((s) {
      final model = s.model;
      final videoUrl = model?.videoUrl;
      if (videoUrl != null && videoUrl.trim().isNotEmpty) {
        return VideoFrameService.frameAt(
          videoUrl,
          timeMs: VideoFrameService.midpointMs(model!.defaultHoldSeconds),
        );
      }
      return Future.value(null);
    }).toList();

    _framesFuture = Future.wait(futures);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Uint8List?>>(
      future: _framesFuture,
      builder: (context, snapshot) {
        // Show full container shimmer until all data and stretch images are loaded
        if (snapshot.connectionState != ConnectionState.done) {
          return const TodayPlanCardShimmer();
        }
        return _buildCardContent(context);
      },
    );
  }

  Widget _buildCardContent(BuildContext context) {
    final colors = context.colors;
    final plan = widget.plan;
    final isCompleted = widget.isCompleted;
    final resumeFromStretch = widget.resumeFromStretch;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Today's plan · ${plan.durationText}",
            style: AppTextStyle.eyebrow.copyWith(color: colors.ink3),
          ),
          2.verticalSpace,
          Text(plan.name, style: AppTextStyle.display(24)),
          14.verticalSpace,
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final stretch in plan.stretches) ...[
                  StretchThumbnail(stretch: stretch),
                  6.horizontalSpace,
                ],
              ],
            ),
          ),
          if (resumeFromStretch != null && !isCompleted) ...[
            6.verticalSpace,
            Text(
              'Paused · stretch ${resumeFromStretch + 1} of ${plan.stretches.length}'
              '${plan.stretches.length > resumeFromStretch ? ': ${plan.stretches[resumeFromStretch].name}' : ''}',
              style: AppTextStyle.meta.copyWith(color: colors.ink2),
            ),
          ],
          if (plan.tags.isNotEmpty || isCompleted) ...[
            10.verticalSpace,
            Wrap(
              spacing: 6.w,
              runSpacing: 6.h,
              children: [
                if (isCompleted)
                  const AppTag(
                    label: 'Completed today',
                    tone: AppTone.accent,
                    icon: Icons.check_circle_rounded,
                  ),
                for (final tag in plan.tags)
                  AppTag(label: tag, tone: AppTone.accent),
              ],
            ),
          ],
          14.verticalSpace,
          Row(
            children: [
              Expanded(child: _primaryAction()),
              10.horizontalSpace,
              Expanded(
                child: AppButton(
                  label: 'See stretches',
                  variant: AppButtonVariant.secondary,
                  onPressed: widget.onSeeStretches,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Picks the right primary button for the card's three states: Restart when
  /// today's plan is done, Resume when a paused attempt exists, else Start.
  Widget _primaryAction() {
    if (widget.isCompleted) {
      return AppButton(
        label: 'Restart',
        icon: Icons.refresh_rounded,
        variant: AppButtonVariant.secondary,
        onPressed: widget.onRestart ?? widget.onStart,
      );
    }
    if (widget.resumeFromStretch != null) {
      return AppButton(
        label: 'Resume',
        icon: Icons.play_arrow_rounded,
        onPressed: widget.onResume ?? widget.onStart,
      );
    }
    return AppButton(
      label: 'Start',
      icon: Icons.play_arrow_rounded,
      onPressed: widget.onStart,
    );
  }
}
