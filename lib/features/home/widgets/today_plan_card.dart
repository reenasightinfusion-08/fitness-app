import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fitness_app/core/theme/theme.dart';
import 'package:fitness_app/core/widgets/widgets.dart';
import 'package:fitness_app/features/home/models/today_plan.dart';
import 'package:fitness_app/features/home/widgets/stretch_thumbnail.dart';

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
          AppShimmer.box(width: 76.w, height: 26.h, borderRadius: 100.r),
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
class TodayPlanCard extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final colors = context.colors;
    final size = MediaQuery.sizeOf(context);
    final isTablet = size.width >= 600;

    final eyebrowStyle = AppTextStyle.eyebrow.copyWith(
      color: colors.ink3,
      fontSize: isTablet ? 12.0 : null,
    );
    final titleStyle = AppTextStyle.display(24);
    final metaStyle = AppTextStyle.meta.copyWith(
      color: colors.ink2,
      fontSize: isTablet ? 13.0 : null,
    );

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Today's plan · ${plan.durationText}", style: eyebrowStyle),
          (isTablet ? 4.0 : 2.0).verticalSpace,
          Text(plan.name, style: titleStyle),
          (isTablet ? 14.0 : 14.0).verticalSpace,
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final stretch in plan.stretches) ...[
                  StretchThumbnail(
                    stretch: stretch,
                    size: AppThumbSize.medium,
                  ),
                  (isTablet ? 8.0 : 6.0).horizontalSpace,
                ],
              ],
            ),
          ),
          if (resumeFromStretch != null && !isCompleted) ...[
            (isTablet ? 8.0 : 6.0).verticalSpace,
            Text(
              'Paused · stretch ${resumeFromStretch! + 1} of ${plan.stretches.length}'
              '${plan.stretches.length > resumeFromStretch! ? ': ${plan.stretches[resumeFromStretch!].name}' : ''}',
              style: metaStyle,
            ),
          ],
          if (plan.tags.isNotEmpty || isCompleted) ...[
            (isTablet ? 12.0 : 10.0).verticalSpace,
            Wrap(
              spacing: isTablet ? 6.0 : 6.w,
              runSpacing: isTablet ? 6.0 : 6.h,
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
          (isTablet ? 16.0 : 14.0).verticalSpace,
          Row(
            children: [
              Expanded(child: _primaryAction(isTablet ? 50.0 : null)),
              (isTablet ? 10.0 : 10.0).horizontalSpace,
              Expanded(
                child: AppButton(
                  label: 'See stretches',
                  variant: AppButtonVariant.secondary,
                  onPressed: onSeeStretches,
                  minHeight: isTablet ? 50.0 : null,
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
  Widget _primaryAction([double? minHeight]) {
    if (isCompleted) {
      return AppButton(
        label: 'Restart',

        icon: Icons.refresh_rounded,
        variant: AppButtonVariant.secondary,
        onPressed: onRestart ?? onStart,
        minHeight: minHeight,
      );
    }
    if (resumeFromStretch != null) {
      return AppButton(
        label: 'Resume',
        icon: Icons.play_arrow_rounded,
        onPressed: onResume ?? onStart,
        minHeight: minHeight,
      );
    }
    return AppButton(
      label: 'Start',
      icon: Icons.play_arrow_rounded,
      onPressed: onStart,
      minHeight: minHeight,
    );
  }
}
