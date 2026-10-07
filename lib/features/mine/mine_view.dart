import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:fitness_app/core/providers/providers.dart';
import 'package:fitness_app/core/theme/theme.dart';
import 'package:fitness_app/core/widgets/widgets.dart';
import 'package:fitness_app/features/home/models/active_routine_model.dart';
import 'package:fitness_app/features/home/models/today_plan.dart';
import 'package:fitness_app/features/home/widgets/stretch_thumbnail.dart';
import 'package:fitness_app/features/routine_builder/routine_builder_screen.dart';
import 'package:fitness_app/features/routine_detail/routine_detail_screen.dart';
import 'package:fitness_app/features/session_player/session_player_screen.dart';
import 'package:fitness_app/services/auth_service.dart';
import 'package:fitness_app/services/paused_session_cache.dart';
import 'package:fitness_app/services/video_frame_service.dart';

/// Wireframe shimmer placeholder matching an incomplete routine card.
class MineIncompleteRoutineCardShimmer extends StatelessWidget {
  const MineIncompleteRoutineCardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Material(
      color: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: AppBorderRadius.xxl,
        side: BorderSide(color: colors.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: EdgeInsets.all(12.r),
        child: Row(
          children: [
            // Thumbnail medium square skeleton (48x48)
            AppShimmer.box(width: 48.r, height: 48.r, borderRadius: 14.r),
            12.horizontalSpace,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Title text line skeleton
                  AppShimmer.box(width: 135.w, height: 16.h, borderRadius: 4.r),
                  4.verticalSpace,
                  // Subtitle text line skeleton
                  AppShimmer.box(width: 110.w, height: 12.h, borderRadius: 4.r),
                ],
              ),
            ),
            8.horizontalSpace,
            // Play icon button skeleton
            AppShimmer.box(width: 32.r, height: 32.r, borderRadius: 100.r),
          ],
        ),
      ),
    );
  }
}

/// Wireframe shimmer placeholder matching a custom or favorite routine card.
class MineRoutineCardShimmer extends StatelessWidget {
  const MineRoutineCardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Material(
      color: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: AppBorderRadius.xxl,
        side: BorderSide(color: colors.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: EdgeInsets.all(12.r),
        child: Row(
          children: [
            // Large thumbnail square skeleton (64x64)
            AppShimmer.box(width: 64.r, height: 64.r, borderRadius: 16.r),
            14.horizontalSpace,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Routine title skeleton
                  AppShimmer.box(width: 140.w, height: 16.h, borderRadius: 4.r),
                  6.verticalSpace,
                  // Duration/meta text skeleton
                  AppShimmer.box(width: 110.w, height: 12.h, borderRadius: 4.r),
                ],
              ),
            ),
            12.horizontalSpace,
            // Chevron arrow icon skeleton
            AppShimmer.box(width: 12.w, height: 18.h, borderRadius: 4.r),
          ],
        ),
      ),
    );
  }
}

/// Matches the prototype's `screens.mine`: routines you built yourself and
/// favourited routines. There's no custom-stretch flow, so that third
/// section from the prototype is left out; "Built by you" is backed by
/// [customRoutinesProvider] (stored on the server) and "Favourites" by
/// [favoritesProvider].
class MineView extends ConsumerWidget {
  const MineView({super.key});

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
    final favoritesAsync = ref.watch(favoritesProvider);
    final routinesAsync = ref.watch(routinesProvider);
    final libraryRoutines = routinesAsync.valueOrNull ?? const <RoutineSummary>[];
    final customAsync = ref.watch(customRoutinesProvider);
    final customRoutines = customAsync.valueOrNull ?? const <RoutineSummary>[];
    final customIds = {
      for (final routine in customRoutines)
        if (routine.id != null) routine.id,
    };
    final pausedUserAsync = ref.watch(pausedUserRoutinesProvider);

    // A favourite is just an id; look it up among the library and custom routines.
    final byId = {
      for (final r in [...libraryRoutines, ...customRoutines])
        if (r.id != null) r.id!: r,
    };
    final favoriteIds = favoritesAsync.valueOrNull ?? const <String>[];
    final favorites = [
      for (final id in favoriteIds)
        if (byId[id] != null) byId[id]!,
    ];

    // Check if Favourites section is still waiting for favorite IDs or routine definitions
    final isFavoritesLoading = (favoritesAsync.isLoading && !favoritesAsync.hasValue) ||
        (routinesAsync.isLoading && !routinesAsync.hasValue) ||
        (customAsync.isLoading && !customAsync.hasValue);

    // Dynamic shimmer counts matching the actual cached list count when available
    final customShimmerCount = customRoutines.isNotEmpty ? customRoutines.length : 1;
    final favoritesShimmerCount = favoriteIds.isNotEmpty
        ? favoriteIds.length
        : (favorites.isNotEmpty ? favorites.length : 1);

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
        pausedUserAsync.when(
          data: (otherPaused) {
            if (otherPaused.isEmpty) return const SizedBox.shrink();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                24.verticalSpace,
                Text('Incomplete routines', style: AppTextStyle.sectionTitle),
                10.verticalSpace,
                for (var i = 0; i < otherPaused.length; i++) ...[
                  if (i > 0) 10.verticalSpace,
                  _IncompleteRoutineCard(active: otherPaused[i]),
                ],
              ],
            );
          },
          loading: () {
            if (!PausedSessionCache.hasPausedRoutine) {
              return const SizedBox.shrink();
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                24.verticalSpace,
                Text('Incomplete routines', style: AppTextStyle.sectionTitle),
                10.verticalSpace,
                const MineIncompleteRoutineCardShimmer(),
              ],
            );
          },
          error: (error, stack) => const SizedBox.shrink(),
        ),
        24.verticalSpace,
        Text('Built by you', style: AppTextStyle.sectionTitle),
        10.verticalSpace,
        if (customAsync.isLoading && !customAsync.hasValue)
          Column(
            children: [
              for (var i = 0; i < customShimmerCount; i++) ...[
                if (i > 0) 10.verticalSpace,
                const MineRoutineCardShimmer(),
              ],
            ],
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
        if (isFavoritesLoading)
          Column(
            children: [
              for (var i = 0; i < favoritesShimmerCount; i++) ...[
                if (i > 0) 10.verticalSpace,
                const MineRoutineCardShimmer(),
              ],
            ],
          )
        else if (favorites.isEmpty)
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
class _IncompleteRoutineCard extends ConsumerStatefulWidget {
  const _IncompleteRoutineCard({required this.active});

  final ActiveRoutineModel active;

  @override
  ConsumerState<_IncompleteRoutineCard> createState() =>
      _IncompleteRoutineCardState();
}

class _IncompleteRoutineCardState
    extends ConsumerState<_IncompleteRoutineCard> {
  late Future<Uint8List?> _frameFuture;

  @override
  void initState() {
    super.initState();
    _initFrameFuture();
  }

  @override
  void didUpdateWidget(covariant _IncompleteRoutineCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.active != widget.active) {
      _initFrameFuture();
    }
  }

  void _initFrameFuture() {
    final next = widget.active.nextStretch;
    final videoUrl = next?.model?.videoUrl;
    if (videoUrl != null && videoUrl.trim().isNotEmpty) {
      _frameFuture = VideoFrameService.frameAt(
        videoUrl,
        timeMs: VideoFrameService.midpointMs(
          next?.model?.defaultHoldSeconds ?? 30,
        ),
      );
    } else {
      _frameFuture = Future.value(null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List?>(
      future: _frameFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const MineIncompleteRoutineCardShimmer();
        }
        return _buildCardContent(context);
      },
    );
  }

  Widget _buildCardContent(BuildContext context) {
    final active = widget.active;
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
        onTap: () => _resume(context),
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
                onPressed: () => _resume(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _resume(BuildContext context) => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => SessionPlayerScreen(
            plan: widget.active.routine,
            startStretchIndex: widget.active.completedStretch,
            onProgress: trackProgress(
              ProviderScope.containerOf(context),
              widget.active,
            ),
          ),
        ),
      );
}

class _RoutineCard extends StatefulWidget {
  const _RoutineCard({required this.routine, this.routineType = 'system'});

  final RoutineSummary routine;
  final String routineType;

  @override
  State<_RoutineCard> createState() => _RoutineCardState();
}

class _RoutineCardState extends State<_RoutineCard> {
  late Future<Uint8List?> _frameFuture;

  @override
  void initState() {
    super.initState();
    _initFrameFuture();
  }

  @override
  void didUpdateWidget(covariant _RoutineCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.routine != widget.routine) {
      _initFrameFuture();
    }
  }

  void _initFrameFuture() {
    final firstStretch = widget.routine.stretches.isNotEmpty
        ? widget.routine.stretches.first
        : null;
    final videoUrl = firstStretch?.model?.videoUrl;
    if (videoUrl != null && videoUrl.trim().isNotEmpty) {
      _frameFuture = VideoFrameService.frameAt(
        videoUrl,
        timeMs: VideoFrameService.midpointMs(
          firstStretch?.model?.defaultHoldSeconds ?? 30,
        ),
      );
    } else {
      _frameFuture = Future.value(null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List?>(
      future: _frameFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const MineRoutineCardShimmer();
        }
        return _buildCardContent(context, snapshot.data);
      },
    );
  }

  Widget _buildCardContent(BuildContext context, Uint8List? frameBytes) {
    final routine = widget.routine;
    final firstStretch =
        routine.stretches.isNotEmpty ? routine.stretches.first : null;
    final pose = firstStretch?.pose ?? StretchPoses.neutral;
    final thumbUrl = firstStretch?.model?.thumbnailUrl;
    final hasThumb = thumbUrl != null && thumbUrl.trim().isNotEmpty;

    Widget thumbnailWidget;
    if (frameBytes != null) {
      thumbnailWidget = ClipRRect(
        borderRadius: AppBorderRadius.md,
        child: Image.memory(
          frameBytes,
          fit: BoxFit.cover,
          gaplessPlayback: true,
        ),
      );
    } else if (hasThumb) {
      thumbnailWidget = ClipRRect(
        borderRadius: AppBorderRadius.md,
        child: Image.network(
          thumbUrl,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) =>
              StretchFigure(pose: pose),
        ),
      );
    } else {
      thumbnailWidget = StretchFigure(pose: pose);
    }

    return AppRoutineCard(
      title: routine.name,
      meta: '${routine.durationText} · ${routine.stretches.length} stretches',
      thumbnail: AppThumb(
        size: AppThumbSize.large,
        child: thumbnailWidget,
      ),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => RoutineDetailScreen(
            routine: routine,
            routineType: widget.routineType,
          ),
        ),
      ),
    );
  }
}

/// A "Built by you" card, swipe-to-delete with a confirm step — mirrors the
/// prototype's `delRoutineYes` flow.
class _CustomRoutineCard extends StatelessWidget {
  const _CustomRoutineCard({required this.routine, required this.onDelete});

  final RoutineSummary routine;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) => AppSwipeableCard(
    onDelete: onDelete,
    confirmTitle: 'Delete this routine?',
    confirmMessage: '"${routine.name}" will be removed. This can\'t be undone.',
    child: _RoutineCard(routine: routine, routineType: 'custom'),
  );
}
