import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:fitness_app/core/providers/providers.dart';
import 'package:fitness_app/core/theme/theme.dart';
import 'package:fitness_app/core/widgets/widgets.dart';
import 'package:fitness_app/features/explore/models/explore_data.dart';
import 'package:fitness_app/features/home/models/active_routine_model.dart';
import 'package:fitness_app/features/home/models/today_plan.dart';
import 'package:fitness_app/features/home/widgets/stretch_thumbnail.dart';
import 'package:fitness_app/features/routine_builder/routine_builder_screen.dart';
import 'package:fitness_app/features/routine_detail/routine_detail_screen.dart';
import 'package:fitness_app/features/session_player/session_player_screen.dart';
import 'package:fitness_app/services/auth_service.dart';

/// Matches the prototype's `screens.mine`: routines you built yourself and
/// favourited routines. There's no custom-stretch flow, so that third
/// section from the prototype is left out; "Built by you" is backed by
/// [customRoutinesProvider] (stored on the server) and "Favourites" by
/// [favoritesProvider].
class MineView extends ConsumerWidget {
  const MineView({super.key});

  /// Every routine the app currently knows about, searched by name to turn
  /// a favourited id back into a [RoutineSummary] — there's no shared
  /// routine repository yet, so Today's plan/quick picks and Explore's
  /// list are each demo data of their own.
  static List<RoutineSummary> _knownRoutines(List<RoutineSummary> custom) => [
    TodayDemoData.todaysPlan,
    ...TodayDemoData.quickPicks,
    for (final routine in ExploreDemoData.routines) routine.toRoutineSummary(),
    ...custom,
  ];

  /// The card is already swiped away, so a failed delete puts it back and
  /// says why — from here rather than the card, which is gone by then.
  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    RoutineSummary routine,
  ) async {
    final id = routine.id;
    if (id == null) return;
    try {
      await ref.read(customRoutinesProvider.notifier).remove(id);
    } catch (error) {
      if (!context.mounted) return;
      AppSnackBar.showError(
        context,
        error is AuthException
            ? error.message
            : "Couldn't delete the routine. Try again.",
      );
    }
  }

  void _openBuilder(BuildContext context) => Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => const RoutineBuilderScreen()),
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favoriteIds = ref.watch(favoritesProvider);
    final customAsync = ref.watch(customRoutinesProvider);
    final customRoutines = customAsync.valueOrNull ?? const <RoutineSummary>[];
    final customIds = {
      for (final routine in customRoutines)
        if (routine.id != null) routine.id,
    };
    // The newest paused library routine shows in the Today banner; the rest
    // live here, so a user can resume any one of them.
    final otherPaused =
        ref.watch(pausedUserRoutinesProvider).valueOrNull?.skip(1).toList() ??
        const <ActiveRoutineModel>[];
    final byName = {for (final r in _knownRoutines(customRoutines)) r.name: r};
    final favorites = [
      for (final id in favoriteIds)
        if (byName[id] != null) byName[id]!,
    ];

    return ListView(
      padding: AppInsets.page,
      children: [
        Text('My routines', style: AppTextStyle.headline),
        18.verticalSpace,
        AppButton(
          label: 'Create a routine',
          icon: Icons.add_rounded,
          onPressed: () => _openBuilder(context),
        ),
        if (otherPaused.isNotEmpty) ...[
          24.verticalSpace,
          Text('Incomplete routines', style: AppTextStyle.sectionTitle),
          10.verticalSpace,
          for (var i = 0; i < otherPaused.length; i++) ...[
            if (i > 0) 10.verticalSpace,
            _IncompleteRoutineCard(active: otherPaused[i]),
          ],
        ],
        24.verticalSpace,
        Text('Built by you', style: AppTextStyle.sectionTitle),
        10.verticalSpace,
        if (customAsync.isLoading && !customAsync.hasValue)
          Padding(
            padding: EdgeInsets.symmetric(vertical: 24.h),
            child: const Center(child: AppLoader()),
          )
        else if (customAsync.hasError && !customAsync.hasValue)
          AppEmptyState(
            icon: Icons.cloud_off_rounded,
            title: "Couldn't load your routines",
            message: customAsync.error is AuthException
                ? customAsync.error.toString()
                : 'Check your connection and try again.',
            actionLabel: 'Try again',
            onAction: () => ref.invalidate(customRoutinesProvider),
          )
        else if (customRoutines.isEmpty)
          const AppEmptyState(
            icon: Icons.list_alt_rounded,
            title: 'No routines yet',
            message:
                'Pick stretches, set your own hold times, and they play in '
                'exactly your order.',
          )
        else
          for (var i = 0; i < customRoutines.length; i++) ...[
            if (i > 0) 10.verticalSpace,
            _CustomRoutineCard(
              routine: customRoutines[i],
              onDelete: () => _delete(context, ref, customRoutines[i]),
            ),
          ],
        24.verticalSpace,
        Text('Favourites', style: AppTextStyle.sectionTitle),
        10.verticalSpace,
        if (favorites.isEmpty)
          const AppEmptyState(
            icon: Icons.favorite_border_rounded,
            title: 'No favourites yet',
            message: 'Tap the heart on any routine to keep it here.',
          )
        else
          for (var i = 0; i < favorites.length; i++) ...[
            if (i > 0) 10.verticalSpace,
            _RoutineCard(
              routine: favorites[i],
              routineType: customIds.contains(favorites[i].id)
                  ? 'custom'
                  : 'system',
            ),
          ],
      ],
    );
  }
}

/// A paused routine that is not the most recent one (that one lives in the
/// Today banner). Tap anywhere on the card to resume at the stretch the user
/// stopped at.
class _IncompleteRoutineCard extends ConsumerWidget {
  const _IncompleteRoutineCard({required this.active});

  final ActiveRoutineModel active;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final total = active.routine.stretches.length;
    final next = active.nextStretch;
    final subtitle = next == null
        ? '$total stretches'
        : 'Stretch ${active.completedStretch + 1} of $total: ${next.name}';
    return Material(
      color: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: AppBorderRadius.xxl,
        side: BorderSide(color: colors.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _resume(context, ref),
        child: Padding(
          padding: EdgeInsets.all(12.r),
          child: Row(
            children: [
              next == null
                  ? const AppThumb()
                  : StretchThumbnail(stretch: next),
              12.horizontalSpace,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      active.routine.name,
                      style: AppTextStyle.titleSmall.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    2.verticalSpace,
                    Text(
                      subtitle,
                      style: AppTextStyle.meta.copyWith(color: colors.ink2),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              8.horizontalSpace,
              AppIconButton(
                icon: Icons.play_arrow_rounded,
                tooltip: 'Resume',
                onPressed: () => _resume(context, ref),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _resume(BuildContext context, WidgetRef ref) =>
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
}

class _RoutineCard extends StatelessWidget {
  const _RoutineCard({required this.routine, this.routineType = 'system'});

  final RoutineSummary routine;
  final String routineType;

  @override
  Widget build(BuildContext context) => AppRoutineCard(
    title: routine.name,
    meta:
        '${routine.minutes} min · ${routine.stretches.length} stretches · '
        '${routine.sequenceLabel}',
    thumbnail: StretchThumbnail(
      stretch: routine.stretches.first,
      size: AppThumbSize.large,
    ),
    onTap: () => Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            RoutineDetailScreen(routine: routine, routineType: routineType),
      ),
    ),
  );
}

/// A "Built by you" card, swipe-to-delete with a confirm step — mirrors the
/// prototype's `delRoutineYes` flow.
class _CustomRoutineCard extends StatelessWidget {
  const _CustomRoutineCard({required this.routine, required this.onDelete});

  final RoutineSummary routine;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) => Dismissible(
    key: ValueKey(routine.id ?? routine.name),
    direction: DismissDirection.endToStart,
    background: Container(
      alignment: Alignment.centerRight,
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      decoration: BoxDecoration(
        color: context.colors.danger,
        borderRadius: AppBorderRadius.xxl,
      ),
      child: Icon(Icons.delete_outline_rounded, color: AppColors.white),
    ),
    confirmDismiss: (_) => AppBottomSheet.confirm(
      context,
      title: 'Delete this routine?',
      message: '"${routine.name}" will be removed. This can\'t be undone.',
      confirmLabel: 'Delete routine',
      isDestructive: true,
    ),
    onDismissed: (_) => onDelete(),
    child: _RoutineCard(routine: routine, routineType: 'custom'),
  );
}
