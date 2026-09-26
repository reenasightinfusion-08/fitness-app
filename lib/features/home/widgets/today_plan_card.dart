import 'package:flutter/material.dart';

import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:fitness_app/core/theme/theme.dart';
import 'package:fitness_app/core/widgets/widgets.dart';
import 'package:fitness_app/features/home/models/today_plan.dart';

/// The prototype's `.card.plan`: today's routine name and length, a row of
/// its first five stretch illustrations, why-it-fits tags, and Start /
/// See stretches actions.
class TodayPlanCard extends StatelessWidget {
  const TodayPlanCard({
    super.key,
    required this.plan,
    required this.onStart,
    required this.onSeeStretches,
  });

  final RoutineSummary plan;
  final VoidCallback onStart;
  final VoidCallback onSeeStretches;

  static const _maxThumbnails = 5;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final shown = plan.stretches.take(_maxThumbnails).toList();
    final overflow = plan.stretches.length - shown.length;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Today's plan · ${plan.minutes} min",
            style: AppTextStyle.eyebrow.copyWith(color: colors.ink3),
          ),
          2.verticalSpace,
          Text(plan.name, style: AppTextStyle.display(24)),
          14.verticalSpace,
          Row(
            children: [
              for (final stretch in shown) ...[
                AppThumb(child: StretchFigure(pose: stretch.pose)),
                6.horizontalSpace,
              ],
              if (overflow > 0)
                Text(
                  '+$overflow',
                  style: AppTextStyle.titleSmall.copyWith(color: colors.ink2),
                ),
            ],
          ),
          if (plan.tags.isNotEmpty) ...[
            10.verticalSpace,
            Wrap(
              spacing: 6.w,
              runSpacing: 6.h,
              children: [
                for (final tag in plan.tags)
                  AppTag(label: tag, tone: AppTone.accent),
              ],
            ),
          ],
          14.verticalSpace,
          Row(
            children: [
              Expanded(
                child: AppButton(
                  label: 'Start',
                  icon: Icons.play_arrow_rounded,
                  onPressed: onStart,
                ),
              ),
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
}
