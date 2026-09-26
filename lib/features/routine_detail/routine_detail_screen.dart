import 'package:flutter/material.dart';

import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:fitness_app/core/theme/theme.dart';
import 'package:fitness_app/core/widgets/widgets.dart';
import 'package:fitness_app/features/get_ready/get_ready_screen.dart';
import 'package:fitness_app/features/home/models/today_plan.dart';
import 'package:fitness_app/features/stretch_detail/stretch_detail_sheet.dart';

/// Matches the prototype's `screens.routine`: what a routine contains and
/// why, before committing to it. Reached by tapping any routine card —
/// a quick pick, today's plan, or (once built) a search result.
class RoutineDetailScreen extends StatefulWidget {
  const RoutineDetailScreen({super.key, required this.routine});

  final RoutineSummary routine;

  @override
  State<RoutineDetailScreen> createState() => RoutineDetailScreenState();
}

class RoutineDetailScreenState extends State<RoutineDetailScreen> {
  bool isFavorite = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final routine = widget.routine;
    final firstStretch = routine.stretches.first;

    return Scaffold(
      backgroundColor: colors.ground,
      appBar: AppTopBar(
        onBack: () => Navigator.of(context).pop(),
        trailing: AppIconButton(
          icon: Icons.favorite_border_rounded,
          activeIcon: Icons.favorite_rounded,
          isActive: isFavorite,
          tooltip: isFavorite ? 'Remove from favourites' : 'Add to favourites',
          onPressed: () => setState(() => isFavorite = !isFavorite),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: AppInsets.page,
                children: [
                  AspectRatio(
                    aspectRatio: 16 / 9,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: colors.surface,
                        border: Border.all(color: colors.line),
                        borderRadius: AppBorderRadius.hero,
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(28.r),
                        child: StretchFigure(pose: firstStretch.pose),
                      ),
                    ),
                  ),
                  16.verticalSpace,
                  Text(routine.name, style: AppTextStyle.headline),
                  if (routine.blurb != null) ...[
                    6.verticalSpace,
                    Text(
                      routine.blurb!,
                      style: AppTextStyle.bodyMedium.copyWith(
                        color: colors.ink2,
                      ),
                    ),
                  ],
                  16.verticalSpace,
                  Row(
                    children: [
                      Expanded(
                        child: AppFactTile(
                          label: 'Time',
                          value: '${routine.minutes} min',
                        ),
                      ),
                      8.horizontalSpace,
                      Expanded(
                        child: AppFactTile(
                          label: 'Level',
                          value: routine.level.label,
                        ),
                      ),
                      8.horizontalSpace,
                      Expanded(
                        child: AppFactTile(
                          label: 'Equipment',
                          value: routine.equipmentLabel,
                        ),
                      ),
                    ],
                  ),
                  12.verticalSpace,
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 16.r,
                        color: colors.ink3,
                      ),
                      6.horizontalSpace,
                      Expanded(
                        child: Text(
                          routine.sequenceLabel,
                          style: AppTextStyle.meta.copyWith(
                            color: colors.ink2,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (routine.adaptedNotes.isNotEmpty) ...[
                    12.verticalSpace,
                    AppNote(
                      title: 'Adapted for you',
                      message: routine.adaptedNotes
                          .map((note) => '•  $note')
                          .join('\n'),
                    ),
                  ],
                  20.verticalSpace,
                  Text('Stretches', style: AppTextStyle.sectionTitle),
                  for (var i = 0; i < routine.stretches.length; i++)
                    AppSettingRow(
                      title: routine.stretches[i].name,
                      subtitle:
                          '${routine.stretches[i].holdSeconds}s'
                          '${routine.stretches[i].isEachSide ? ' each side' : ''}'
                          ' · ${routine.stretches[i].position.label}',
                      leading: AppThumb(
                        child: StretchFigure(pose: routine.stretches[i].pose),
                      ),
                      trailing: Icon(
                        Icons.info_outline_rounded,
                        size: 18.r,
                        color: colors.ink3,
                      ),
                      onTap: () => StretchDetailSheet.open(
                        context,
                        name: routine.stretches[i].name,
                        pose: routine.stretches[i].pose,
                      ),
                      showDivider: i < routine.stretches.length - 1,
                    ),
                ],
              ),
            ),
            AppBottomActionBar(
              children: [
                AppButton(
                  label: 'Start · ${routine.minutes} min',
                  icon: Icons.play_arrow_rounded,
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => GetReadyScreen(plan: routine),
                    ),
                  ),
                ),
                AppButton(
                  label: 'Customise a copy',
                  variant: AppButtonVariant.text,
                  onPressed: () => AppSnackBar.show(
                    context,
                    "That screen isn't built yet.",
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
