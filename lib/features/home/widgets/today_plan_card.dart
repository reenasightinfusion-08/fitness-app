import 'package:flutter/material.dart';

import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:fitness_app/core/theme/theme.dart';
import 'package:fitness_app/core/widgets/widgets.dart';
import 'package:fitness_app/features/home/models/today_plan.dart';
import 'package:fitness_app/features/home/widgets/stretch_thumbnail.dart';

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
              'Paused · stretch ${resumeFromStretch! + 1} of ${plan.stretches.length}'
              '${plan.stretches.length > resumeFromStretch! ? ': ${plan.stretches[resumeFromStretch!].name}' : ''}',
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
                  onPressed: onSeeStretches,
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
    if (isCompleted) {
      return AppButton(
        label: 'Restart',
        icon: Icons.refresh_rounded,
        variant: AppButtonVariant.secondary,
        onPressed: onRestart ?? onStart,
      );
    }
    if (resumeFromStretch != null) {
      return AppButton(
        label: 'Resume',
        icon: Icons.play_arrow_rounded,
        onPressed: onResume ?? onStart,
      );
    }
    return AppButton(
      label: 'Start',
      icon: Icons.play_arrow_rounded,
      onPressed: onStart,
    );
  }
}
