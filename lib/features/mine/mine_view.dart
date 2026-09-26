import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:fitness_app/core/providers/providers.dart';
import 'package:fitness_app/core/theme/theme.dart';
import 'package:fitness_app/core/widgets/widgets.dart';
import 'package:fitness_app/features/explore/models/explore_data.dart';
import 'package:fitness_app/features/home/models/today_plan.dart';
import 'package:fitness_app/features/routine_builder/routine_builder_screen.dart';
import 'package:fitness_app/features/routine_detail/routine_detail_screen.dart';

/// Matches the prototype's `screens.mine`: routines you built yourself and
/// favourited routines. There's no custom-stretch flow, so that third
/// section from the prototype is left out; "Built by you" is backed by
/// [customRoutinesProvider] and "Favourites" by [favoritesProvider].
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

  void _openBuilder(BuildContext context) => Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => const RoutineBuilderScreen()),
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favoriteIds = ref.watch(favoritesProvider);
    final customRoutines = ref.watch(customRoutinesProvider);
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
        24.verticalSpace,
        Text('Built by you', style: AppTextStyle.sectionTitle),
        10.verticalSpace,
        if (customRoutines.isEmpty)
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
            _CustomRoutineCard(routine: customRoutines[i]),
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
            _RoutineCard(routine: favorites[i]),
          ],
      ],
    );
  }
}

class _RoutineCard extends StatelessWidget {
  const _RoutineCard({required this.routine});

  final RoutineSummary routine;

  @override
  Widget build(BuildContext context) => AppRoutineCard(
    title: routine.name,
    meta:
        '${routine.minutes} min · ${routine.stretches.length} stretches · '
        '${routine.sequenceLabel}',
    thumbnail: AppThumb(
      size: AppThumbSize.large,
      child: StretchFigure(pose: routine.stretches.first.pose),
    ),
    onTap: () => Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => RoutineDetailScreen(routine: routine)),
    ),
  );
}

/// A "Built by you" card, swipe-to-delete with a confirm step — mirrors the
/// prototype's `delRoutineYes` flow.
class _CustomRoutineCard extends ConsumerWidget {
  const _CustomRoutineCard({required this.routine});

  final RoutineSummary routine;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Dismissible(
    key: ValueKey(routine.name),
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
    onDismissed: (_) =>
        ref.read(customRoutinesProvider.notifier).remove(routine.name),
    child: _RoutineCard(routine: routine),
  );
}
