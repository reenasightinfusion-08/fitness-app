import 'package:fitness_app/features/explore/models/explore_data.dart';
import 'package:fitness_app/features/home/models/today_plan.dart';
import 'package:fitness_app/features/onboarding_setup/models/onboarding_options.dart';
import 'package:flutter/material.dart';

import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:fitness_app/core/theme/theme.dart';
import 'package:fitness_app/core/widgets/widgets.dart';
import 'package:fitness_app/features/stretch_detail/models/stretch_guide.dart';
import 'package:fitness_app/features/stretch_detail/models/stretch_model.dart';

/// Matches the prototype's `stretchSheet()`: the modal reached from every
/// info icon next to a stretch — a bigger look at the pose, what it works,
/// how to do it, and when to be careful.
class StretchDetailSheet extends StatelessWidget {
  const StretchDetailSheet({
    super.key,
    this.name,
    this.pose,
    this.model,
    this.note,
  });

  final String? name;
  final StretchPose? pose;
  final StretchModel? model;

  /// e.g. "Timer paused while you read." — shown when opened mid-session.
  final String? note;

  static Future<void> open(
    BuildContext context, {
    String? name,
    StretchPose? pose,
    StretchModel? model,
    String? note,
  }) => AppBottomSheet.show(
    context,
    child: StretchDetailSheet(
      name: name,
      pose: pose,
      model: model,
      note: note,
    ),
  );

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final effectivePose = model?.pose ?? pose ?? StretchPoses.neutral;
    final effectiveName = model?.name ?? name ?? '';
    final guide = model?.toGuide() ?? (pose != null ? StretchLibrary.guideFor(pose!) : null);
    final hasThumb = model?.thumbnailUrl != null && model!.thumbnailUrl!.trim().isNotEmpty;

    final matches = ExploreDemoData.stretches.where(
      (s) => s.pose == effectivePose || s.name == effectiveName,
    );
    final rawAreas = model?.areas.isNotEmpty == true
        ? model!.areas
        : (matches.isNotEmpty ? matches.first.areas : const <String>[]);

    final areaLabels = rawAreas.map((areaKey) {
      final match = ExploreDemoData.areas.firstWhere(
        (a) => a.key.toLowerCase() == areaKey.toLowerCase(),
        orElse: () => ExploreArea(areaKey, areaKey),
      );
      return match.label;
    }).toList();

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
            child: ClipRRect(
              borderRadius: AppBorderRadius.card,
              child: hasThumb
                  ? Image.network(
                      model!.thumbnailUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Padding(
                        padding: EdgeInsets.all(20.r),
                        child: StretchFigure(pose: effectivePose),
                      ),
                    )
                  : Padding(
                      padding: EdgeInsets.all(20.r),
                      child: StretchFigure(pose: effectivePose),
                    ),
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
        Text(effectiveName, style: AppTextStyle.titleLarge),
        if (guide == null) ...[
          16.verticalSpace,
          Text(
            "We don't have detailed instructions for this one yet.",
            style: AppTextStyle.bodyMedium.copyWith(color: colors.ink2),
          ),
          20.verticalSpace,
        ] else ...[
          if (areaLabels.isNotEmpty) ...[
            8.verticalSpace,
            Wrap(
              spacing: 6.w,
              runSpacing: 6.h,
              children: [
                for (final area in areaLabels) AppTag(label: area),
              ],
            ),
          ],
          12.verticalSpace,
          Row(
            children: [
              Expanded(
                child: AppFactTile(
                  label: 'Position',
                  value: guide.position.label,
                ),
              ),
              8.horizontalSpace,
              Expanded(
                child: AppFactTile(
                  label: 'Level',
                  value: guide.level.label,
                ),
              ),
              8.horizontalSpace,
              Expanded(
                child: AppFactTile(
                  label: 'Equipment',
                  value: guide.equipment.isEmpty
                      ? 'None'
                      : guide.equipment.map((item) {
                          final trimmed = item.trim();
                          if (trimmed.isEmpty) return trimmed;
                          final mapped = equipmentLabels[trimmed.toLowerCase()];
                          if (mapped != null) return mapped;
                          return '${trimmed[0].toUpperCase()}${trimmed.substring(1)}';
                        }).join(', '),
                ),
              ),
            ],
          ),
          16.verticalSpace,
          if (guide.feel.isNotEmpty) ...[
            _Section(title: 'Where you should feel it', body: guide.feel),
            16.verticalSpace,
          ],
          if (guide.steps.isNotEmpty) ...[
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
          ],
          if (guide.commonMistake.isNotEmpty) ...[
            _Section(title: 'Common mistake', body: guide.commonMistake),
            16.verticalSpace,
          ],
          if (guide.easier.isNotEmpty || guide.harder.isNotEmpty) ...[
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (guide.easier.isNotEmpty)
                    Expanded(
                      child: _MiniCard(label: 'Easier', body: guide.easier),
                    ),
                  if (guide.easier.isNotEmpty && guide.harder.isNotEmpty)
                    10.horizontalSpace,
                  if (guide.harder.isNotEmpty)
                    Expanded(
                      child: _MiniCard(label: 'Harder', body: guide.harder),
                    ),
                ],
              ),
            ),
            16.verticalSpace,
          ],
          if (guide.cautions.isNotEmpty) ...[
            AppNote(
              title: 'Take care if…',
              message: guide.cautions,
              tone: AppTone.danger,
            ),
            20.verticalSpace,
          ],
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
