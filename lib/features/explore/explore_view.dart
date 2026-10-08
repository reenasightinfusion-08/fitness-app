import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:fitness_app/core/providers/providers.dart';
import 'package:fitness_app/core/theme/theme.dart';
import 'package:fitness_app/core/utils/app_validators.dart';
import 'package:fitness_app/core/widgets/widgets.dart';
import 'package:fitness_app/features/explore/models/explore_data.dart';
import 'package:fitness_app/features/explore/models/safety_rules.dart';
import 'package:fitness_app/features/home/models/today_plan.dart';
import 'package:fitness_app/features/onboarding_setup/providers/onboarding_profile_provider.dart';
import 'package:fitness_app/features/routine_detail/routine_detail_screen.dart';
import 'package:fitness_app/features/stretch_detail/models/stretch_model.dart';
import 'package:fitness_app/features/stretch_detail/stretch_detail_sheet.dart';
import 'package:fitness_app/services/stretch_service.dart';
import 'package:fitness_app/services/video_frame_service.dart';

/// Full container shimmer for a routine card in Explore view.
class ExploreRoutineCardShimmer extends StatelessWidget {
  const ExploreRoutineCardShimmer({super.key});

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
            // Thumbnail large square skeleton (64x64)
            AppShimmer.box(width: 64.r, height: 64.r, borderRadius: 16.r),
            14.horizontalSpace,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Title text line skeleton
                  AppShimmer.box(width: 140.w, height: 16.h, borderRadius: 4.r),
                  6.verticalSpace,
                  // Duration/stretches count meta text line skeleton
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

/// Full container shimmer for a stretch library tile in Explore view.
class ExploreLibraryTileShimmer extends StatelessWidget {
  const ExploreLibraryTileShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Material(
      color: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: AppBorderRadius.xl,
        side: BorderSide(color: colors.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 15.h),
        child: Column(
          children: [
            // Centered stretch thumbnail 80x80 skeleton
            AppShimmer.box(width: 80.r, height: 80.r, borderRadius: 12.r),
            6.verticalSpace,
            // Stretch name text line skeleton
            AppShimmer.box(width: 60.w, height: 12.h, borderRadius: 4.r),
          ],
        ),
      ),
    );
  }
}

/// Matches the prototype's `screens.explore`: search, a "Safe for me"
/// toggle, area/time filter chips, matching routine cards and the full
/// stretch library.
class ExploreView extends ConsumerStatefulWidget {
  const ExploreView({super.key});

  @override
  ConsumerState<ExploreView> createState() => _ExploreViewState();
}

class _ExploreViewState extends ConsumerState<ExploreView> {
  final _searchController = TextEditingController();
  final _stretchService = StretchService();

  String _query = '';
  String? _area;
  ExploreTimeFilter _time = ExploreTimeFilter.any;
  bool _safeForMe = true;

  List<StretchModel> _apiStretches = [];
  bool _isLoadingStretches = true;
  String? _stretchesError;

  @override
  void initState() {
    super.initState();
    _fetchStretches();
  }

  Future<void> _fetchStretches() async {
    setState(() {
      _isLoadingStretches = true;
      _stretchesError = null;
    });
    try {
      final list = await _stretchService.fetchStretches();
      if (mounted) {
        setState(() {
          _apiStretches = list;
          _isLoadingStretches = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _stretchesError = e.toString();
          _isLoadingStretches = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool _matchesQuery(
    String name,
    List<String> areaKeys, [
    Iterable<String> extraTerms = const [],
  ]) {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return true;
    if (name.toLowerCase().contains(q)) return true;
    if (extraTerms.any((term) => term.toLowerCase().contains(q))) return true;
    return areaKeys.any(
      (key) => ExploreDemoData.areas
          .firstWhere((a) => a.key == key, orElse: () => ExploreArea(key, key))
          .label
          .toLowerCase()
          .contains(q),
    );
  }

  List<String> _routineAreas(RoutineSummary routine) {
    final set = <String>{};
    for (final preview in routine.stretches) {
      if (preview.model?.areas.isNotEmpty == true) {
        set.addAll(preview.model!.areas);
      } else {
        final matches = ExploreDemoData.stretches.where(
          (s) => s.pose == preview.pose || s.name == preview.name,
        );
        if (matches.isNotEmpty) {
          set.addAll(matches.first.areas);
        }
      }
    }
    return set.toList();
  }

  /// What "Safe for me" hides: from the setup answers plus the stretches the
  /// user marked as hurt. Null when the toggle is off.
  SafetyRules? get _safety {
    if (!_safeForMe) return null;
    final hurtIds = <String>{
      for (final h
          in ref.watch(hurtStretchesProvider).valueOrNull ??
              const <HurtStretch>[])
        h.id,
    };
    return SafetyRules.fromProfile(
      ref.watch(onboardingProfileProvider),
      hurtIds,
    );
  }

  List<RoutineSummary> _filterRoutineSummaries(
    List<RoutineSummary> list,
    SafetyRules? safety,
  ) {
    return list.where((r) {
      final areas = _routineAreas(r);
      final matchesQ = _matchesQuery(r.name, areas, [
        ...r.tags,
        for (final s in r.stretches) s.name,
      ]);
      final matchesArea = _area == null || areas.contains(_area);
      final matchesTime = _time.matches(r.totalSeconds);
      final isSafe = safety == null || safety.allowsRoutine(r);
      return matchesQ && matchesArea && matchesTime && isSafe;
    }).toList();
  }

  List<StretchModel> _filteredStretches(SafetyRules? safety) => _apiStretches
      .where((s) => _matchesQuery(s.name, s.areas))
      .where((s) => _area == null || s.areas.contains(_area))
      .where((s) => safety == null || safety.allowsStretch(s))
      .toList();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final safety = _safety;
    final stretches = _filteredStretches(safety);
    final routinesAsync = ref.watch(routinesProvider);

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      behavior: HitTestBehavior.translucent,
      child: ListView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: AppInsets.page,
        children: [
          Text('Explore', style: AppTextStyle.headline),
          14.verticalSpace,
          AppTextField(
            controller: _searchController,
            validator: AppValidators.none,
            variant: AppTextFieldVariant.search,
            hint: 'Search routines, stretches, body areas',
            onChanged: (value) => setState(() => _query = value),
          ),
          14.verticalSpace,
        AppCard(
          variant: AppCardVariant.list,
          child: AppSettingRow(
            title: 'Safe for me',
            subtitle: "Hides stretches and routines that don't suit your body",
            showDivider: false,
            trailing: AppSwitch(
              value: _safeForMe,
              semanticLabel: 'Safe for me',
              onChanged: (value) => setState(() => _safeForMe = value),
            ),
          ),
        ),
        14.verticalSpace,
        AppChipGroup(
          isScrollable: true,
          children: [
            AppChip(
              label: 'All areas',
              isSelected: _area == null,
              onTap: () => setState(() => _area = null),
            ),
            for (final area in ExploreDemoData.areas)
              AppChip(
                label: area.label,
                isSelected: _area == area.key,
                onTap: () => setState(() => _area = area.key),
              ),
          ],
        ),
        10.verticalSpace,
        AppChipGroup(
          children: [
            for (final filter in ExploreTimeFilter.values)
              AppChip(
                label: filter.label,
                isSelected: _time == filter,
                onTap: () => setState(() => _time = filter),
              ),
          ],
        ),
        20.verticalSpace,
        routinesAsync.when(
          data: (apiRoutines) {
            final routines = _filterRoutineSummaries(apiRoutines, safety);
            if (routines.isEmpty) {
              return AppEmptyState(
                icon: Icons.search_off_rounded,
                title: 'No routines match',
                message: _safeForMe
                    ? 'Try a different area or time, or turn off "Safe for me".'
                    : 'Try a different area or time.',
              );
            }
            return Column(
              children: [
                for (var i = 0; i < routines.length; i++) ...[
                  if (i > 0) 10.verticalSpace,
                  _ExploreRoutineTile(routine: routines[i]),
                ],
              ],
            );
          },
          loading: () => Column(
            children: [
              for (var i = 0; i < 5; i++) ...[
                if (i > 0) 10.verticalSpace,
                const ExploreRoutineCardShimmer(),
              ],
            ],
          ),
          error: (err, stack) => Padding(
            padding: EdgeInsets.symmetric(vertical: 12.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Failed to load routines from server.',
                  style: AppTextStyle.bodySmall.copyWith(color: colors.danger),
                ),
                4.verticalSpace,
                TextButton(
                  onPressed: () => ref.invalidate(routinesProvider),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
        24.verticalSpace,
        Text(
          'Stretch library · ${_isLoadingStretches ? '...' : stretches.length}',
          style: AppTextStyle.sectionTitle,
        ),
        10.verticalSpace,
        if (_isLoadingStretches)
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 6,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 8.h,
              crossAxisSpacing: 8.w,
              childAspectRatio: 0.78,
            ),
            itemBuilder: (context, index) => const ExploreLibraryTileShimmer(),
          )
        else if (_stretchesError != null)
          Padding(
            padding: EdgeInsets.symmetric(vertical: 12.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Failed to load stretches from server.',
                  style: AppTextStyle.bodySmall.copyWith(color: colors.danger),
                ),
                4.verticalSpace,
                TextButton(
                  onPressed: _fetchStretches,
                  child: const Text('Retry'),
                ),
              ],
            ),
          )
        else if (stretches.isEmpty)
          Padding(
            padding: EdgeInsets.only(top: 4.h),
            child: Text(
              'No stretches match your filters.',
              style: AppTextStyle.bodySmall.copyWith(color: colors.ink2),
            ),
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: stretches.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 8.h,
              crossAxisSpacing: 8.w,
              childAspectRatio: 0.78,
            ),
            itemBuilder: (context, index) => _LibraryTile(
              stretch: stretches[index],
              onTap: () =>
                  StretchDetailSheet.open(context, model: stretches[index]),
            ),
          ),
      ],
    ),
    );
  }
}

/// Routine card tile with thumbnail preloading + shimmer loading state.
class _ExploreRoutineTile extends StatefulWidget {
  const _ExploreRoutineTile({required this.routine});

  final RoutineSummary routine;

  @override
  State<_ExploreRoutineTile> createState() => _ExploreRoutineTileState();
}

class _ExploreRoutineTileState extends State<_ExploreRoutineTile> {
  late Future<Uint8List?> _frameFuture;

  @override
  void initState() {
    super.initState();
    _initFrameFuture();
  }

  @override
  void didUpdateWidget(covariant _ExploreRoutineTile oldWidget) {
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
          return const ExploreRoutineCardShimmer();
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
      isLocked: false,
      thumbnail: AppThumb(
        size: AppThumbSize.large,
        child: thumbnailWidget,
      ),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => RoutineDetailScreen(routine: routine),
        ),
      ),
    );
  }
}

/// Mirrors the prototype's `.tile`: a centered thumbnail + name, three to
/// a row — distinct from [AppTileCard], which is left-aligned with a meta
/// line for "Quick picks".
class _LibraryTile extends StatefulWidget {
  const _LibraryTile({required this.stretch, required this.onTap});

  final StretchModel stretch;
  final VoidCallback onTap;

  @override
  State<_LibraryTile> createState() => _LibraryTileState();
}

class _LibraryTileState extends State<_LibraryTile> {
  late Future<Uint8List?> _frameFuture;

  @override
  void initState() {
    super.initState();
    _initFrameFuture();
  }

  @override
  void didUpdateWidget(covariant _LibraryTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.stretch != widget.stretch) {
      _initFrameFuture();
    }
  }

  void _initFrameFuture() {
    final videoUrl = widget.stretch.videoUrl;
    if (videoUrl != null && videoUrl.trim().isNotEmpty) {
      _frameFuture = VideoFrameService.frameAt(
        videoUrl,
        timeMs: VideoFrameService.midpointMs(widget.stretch.defaultHoldSeconds),
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
          return const ExploreLibraryTileShimmer();
        }
        return _buildTileContent(context, snapshot.data);
      },
    );
  }

  Widget _buildTileContent(BuildContext context, Uint8List? frameBytes) {
    final colors = context.colors;
    final stretch = widget.stretch;
    final hasThumb =
        stretch.thumbnailUrl != null && stretch.thumbnailUrl!.trim().isNotEmpty;

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
          stretch.thumbnailUrl!,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) =>
              StretchFigure(pose: stretch.pose),
        ),
      );
    } else {
      thumbnailWidget = StretchFigure(pose: stretch.pose);
    }

    return Material(
      color: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: AppBorderRadius.xl,
        side: BorderSide(color: colors.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: widget.onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 15.h),
          child: Column(
            children: [
              SizedBox(
                width: 80.r,
                height: 80.r,
                child: thumbnailWidget,
              ),
              5.verticalSpace,
              Expanded(
                child: Center(
                  child: Text(
                    stretch.name,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyle.caption.copyWith(
                      fontWeight: FontWeight.w600,
                      height: 1.2,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
