import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:fitness_app/core/providers/providers.dart';
import 'package:fitness_app/core/theme/theme.dart';
import 'package:fitness_app/core/widgets/widgets.dart';
import 'package:fitness_app/features/get_ready/get_ready_screen.dart';
import 'package:fitness_app/features/home/models/today_plan.dart';
import 'package:fitness_app/features/routine_builder/routine_builder_screen.dart';
import 'package:fitness_app/features/stretch_detail/stretch_detail_sheet.dart';
import 'package:fitness_app/services/auth_service.dart';

/// Matches the prototype's `screens.routine`: what a routine contains and
/// why, before committing to it. Reached by tapping any routine card —
/// a quick pick, today's plan, or (once built) a search result. The heart
/// toggle writes to [favoritesProvider] (saved on the user's profile, keyed by
/// routine id), so a routine favourited here shows up in the Mine tab's
/// Favourites list. Routines without a server id have no heart.
class RoutineDetailScreen extends ConsumerWidget {
  const RoutineDetailScreen({
    super.key,
    required this.routine,
    this.routineType = 'system',
  });

  final RoutineSummary routine;

  /// 'custom' for a routine the user built, so starting it is tracked against
  /// their own routines rather than the app's.
  final String routineType;

  Future<void> _toggleFavorite(
    BuildContext context,
    WidgetRef ref,
    String routineId,
  ) async {
    try {
      await ref.read(favoritesProvider.notifier).toggle(routineId);
    } catch (error) {
      if (!context.mounted) return;
      AppSnackBar.showError(
        context,
        error is AuthException
            ? error.message
            : "Couldn't update your favourites. Try again.",
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final firstStretch =
        routine.stretches.isNotEmpty ? routine.stretches.first : null;
    final thumbUrl = firstStretch?.model?.thumbnailUrl;
    final hasThumb = thumbUrl != null && thumbUrl.trim().isNotEmpty;
    final routineId = routine.id;
    final isFavorite =
        routineId != null &&
        (ref.watch(favoritesProvider).valueOrNull?.contains(routineId) ??
            false);

    return Scaffold(
      backgroundColor: colors.ground,
      appBar: AppTopBar(
        onBack: () => Navigator.of(context).pop(),
        trailing: routineId == null
            ? null
            : AppIconButton(
                icon: Icons.favorite_border_rounded,
                activeIcon: Icons.favorite_rounded,
                isActive: isFavorite,
                tooltip: isFavorite
                    ? 'Remove from favourites'
                    : 'Add to favourites',
                onPressed: () => _toggleFavorite(context, ref, routineId),
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
                      child: ClipRRect(
                        borderRadius: AppBorderRadius.hero,
                        child: hasThumb
                            ? Image.network(
                                thumbUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    Padding(
                                  padding: EdgeInsets.all(28.r),
                                  child: StretchFigure(
                                    pose: firstStretch?.pose ??
                                        StretchPoses.neutral,
                                  ),
                                ),
                              )
                            : Padding(
                                padding: EdgeInsets.all(28.r),
                                child: StretchFigure(
                                  pose: firstStretch?.pose ??
                                      StretchPoses.neutral,
                                ),
                              ),
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
                          value: routine.durationText,
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
                  for (var i = 0; i < routine.stretches.length; i++) ...[
                    Builder(
                      builder: (context) {
                        final stretch = routine.stretches[i];
                        final thumbUrl = stretch.model?.thumbnailUrl;
                        final hasThumb =
                            thumbUrl != null && thumbUrl.trim().isNotEmpty;
                        return AppSettingRow(
                          title: stretch.name,
                          subtitle:
                              '${stretch.holdSeconds}s'
                              '${stretch.isEachSide ? ' each side' : ''}'
                              ' · ${stretch.position.label}',
                          leading: AppThumb(
                            child: hasThumb
                                ? Image.network(
                                    thumbUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            StretchFigure(pose: stretch.pose),
                                  )
                                : StretchFigure(pose: stretch.pose),
                          ),
                          trailing: Icon(
                            Icons.info_outline_rounded,
                            size: 18.r,
                            color: colors.ink3,
                          ),
                          onTap: () => StretchDetailSheet.open(
                            context,
                            name: stretch.name,
                            pose: stretch.pose,
                            model: stretch.model,
                          ),
                          showDivider: i < routine.stretches.length - 1,
                        );
                      },
                    ),
                  ],
                ],
              ),
            ),
            AppBottomActionBar(
              children: [
                AppButton(
                  label: 'Start · ${routine.durationText}',
                  icon: Icons.play_arrow_rounded,
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => GetReadyScreen(
                        plan: routine,
                        routineType: routineType,
                      ),
                    ),
                  ),
                ),
                AppButton(
                  label: 'Customise a copy',
                  variant: AppButtonVariant.text,
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) =>
                          RoutineBuilderScreen(initialRoutine: routine),
                    ),
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
