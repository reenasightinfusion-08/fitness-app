import 'package:fitness_app/features/home/models/today_plan.dart';
import 'package:flutter/material.dart';

import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:fitness_app/core/theme/theme.dart';
import 'package:fitness_app/core/widgets/widgets.dart';
import 'package:fitness_app/features/stretch_detail/models/stretch_guide.dart';

/// Matches the prototype's `stretchSheet()`: the modal reached from every
/// info icon next to a stretch — a bigger look at the pose, what it works,
/// how to do it, and when to be careful.
class StretchDetailSheet extends StatelessWidget {
  const StretchDetailSheet({
    super.key,
    required this.name,
    required this.pose,
    this.note,
  });

  final String name;
  final StretchPose pose;

  /// e.g. "Timer paused while you read." — shown when opened mid-session.
  final String? note;

  static Future<void> open(
    BuildContext context, {
    required String name,
    required StretchPose pose,
    String? note,
  }) => AppBottomSheet.show(
    context,
    child: StretchDetailSheet(name: name, pose: pose, note: note),
  );

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final guide = StretchLibrary.guideFor(pose);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AspectRatio(
          aspectRatio: 4 / 3,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: colors.surface2,
              borderRadius: AppBorderRadius.card,
            ),
            child: Padding(
              padding: EdgeInsets.all(20.r),
              child: StretchFigure(pose: pose),
            ),
          ),
        ),
        12.verticalSpace,
        if (note != null) ...[
          AppNote(
            message: note!,
            tone: AppTone.warm,
            icon: Icons.pause_circle_outline_rounded,
          ),
          10.verticalSpace,
        ],
        Text(name, style: AppTextStyle.titleLarge),
        if (guide == null) ...[
          16.verticalSpace,
          Text(
            "We don't have detailed instructions for this one yet.",
            style: AppTextStyle.bodyMedium.copyWith(color: colors.ink2),
          ),
          20.verticalSpace,
        ] else ...[
          8.verticalSpace,
          Wrap(
            spacing: 6.w,
            runSpacing: 6.h,
            children: [
              AppTag(label: guide.position.label),
              if (guide.isEachSide) const AppTag(label: 'Both sides'),
              if (guide.isDynamic) const AppTag(label: 'Moving'),
              AppTag(label: guide.level.label),
              for (final item in guide.equipment) AppTag(label: item),
              if (guide.isKneeling) const AppTag(label: 'Kneeling'),
            ],
          ),
          16.verticalSpace,
          _Section(title: 'Where you should feel it', body: guide.feel),
          16.verticalSpace,
          Text('How to do it', style: AppTextStyle.titleSmall),
          8.verticalSpace,
          for (var i = 0; i < guide.steps.length; i++)
            Padding(
              padding: EdgeInsets.only(bottom: 6.h),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${i + 1}.',
                    style: AppTextStyle.bodyMedium.copyWith(
                      color: colors.ink3,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  8.horizontalSpace,
                  Expanded(
                    child: Text(guide.steps[i], style: AppTextStyle.bodyMedium),
                  ),
                ],
              ),
            ),
          10.verticalSpace,
          _Section(title: 'Common mistake', body: guide.commonMistake),
          16.verticalSpace,
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _MiniCard(label: 'Easier', body: guide.easier),
              ),
              10.horizontalSpace,
              Expanded(
                child: _MiniCard(label: 'Harder', body: guide.harder),
              ),
            ],
          ),
          16.verticalSpace,
          AppNote(
            title: 'Take care if…',
            message: guide.cautions,
            tone: AppTone.danger,
          ),
          20.verticalSpace,
        ],
        AppButton(
          label: 'Close',
          variant: AppButtonVariant.secondary,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(title, style: AppTextStyle.titleSmall),
      4.verticalSpace,
      Text(
        body,
        style: AppTextStyle.bodyMedium.copyWith(color: context.colors.ink2),
      ),
    ],
  );
}

class _MiniCard extends StatelessWidget {
  const _MiniCard({required this.label, required this.body});

  final String label;
  final String body;

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.all(12.r),
    decoration: BoxDecoration(
      color: context.colors.surface2,
      borderRadius: AppBorderRadius.xl,
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyle.eyebrow.copyWith(color: context.colors.ink3),
        ),
        4.verticalSpace,
        Text(body, style: AppTextStyle.bodySmall),
      ],
    ),
  );
}
