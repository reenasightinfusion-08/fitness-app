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
import 'package:fitness_app/core/ads/ad_service.dart';
import 'package:fitness_app/core/ads/ad_slot.dart';
import 'package:fitness_app/features/stretch_detail/stretch_detail_sheet.dart';
import 'package:fitness_app/services/stretch_service.dart';
import 'package:fitness_app/services/video_frame_service.dart';

/// Full container shimmer for a routine card in Explore view.
class ExploreRoutineCardShimmer extends StatelessWidget {
  const ExploreRoutineCardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final size = MediaQuery.sizeOf(context);
    final isTablet = size.width >= 600;

    return Material(
      color: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius:
            isTablet ? BorderRadius.circular(18.0) : AppBorderRadius.xxl,
        side: BorderSide(color: colors.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: EdgeInsets.all(isTablet ? 14.0 : 12.r),
        child: Row(
          children: [
            // Thumbnail large square skeleton (64x64)
            AppShimmer.box(
              width: isTablet ? 64.0 : 64.r,
              height: isTablet ? 64.0 : 64.r,
              borderRadius: isTablet ? 16.0 : 16.r,
            ),
            (isTablet ? 16.0 : 14.0).horizontalSpace,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Title text line skeleton
                  AppShimmer.box(
                    width: isTablet ? 160.0 : 140.w,
                    height: isTablet ? 16.0 : 16.h,
                    borderRadius: 4.r,
                  ),
                  (isTablet ? 6.0 : 6.0).verticalSpace,
                  // Duration/stretches count meta text line skeleton
                  AppShimmer.box(
                    width: isTablet ? 120.0 : 110.w,
                    height: isTablet ? 12.0 : 12.h,
                    borderRadius: 4.r,
                  ),
                ],
              ),
            ),
            (isTablet ? 12.0 : 12.0).horizontalSpace,
            // Chevron arrow icon skeleton
            AppShimmer.box(
              width: isTablet ? 12.0 : 12.w,
              height: isTablet ? 18.0 : 18.h,
              borderRadius: 4.r,
            ),
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
    final size = MediaQuery.sizeOf(context);
    final isTablet = size.width >= 600;
    final thumbSize = isTablet
        ? (size.width >= 1100 ? 98.0 : (size.width >= 850 ? 92.0 : 88.0))
        : 80.r;

    return Material(
      color: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius:
            isTablet ? BorderRadius.circular(18.0) : AppBorderRadius.xl,
        side: BorderSide(color: colors.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: isTablet
            ? const EdgeInsets.symmetric(horizontal: 10.0, vertical: 12.0)
            : EdgeInsets.symmetric(horizontal: 6.w, vertical: 15.h),
        child: Column(
          children: [
            AppShimmer.box(
              width: thumbSize,
              height: thumbSize,
              borderRadius: isTablet ? 14.0 : 12.r,
            ),
            (isTablet ? 10.0 : 6.0).verticalSpace,
            Expanded(
              child: Center(
                child: AppShimmer.box(
                  width: isTablet ? 80.0 : 60.w,
                  height: isTablet ? 14.0 : 12.h,
                  borderRadius: 4.r,
                ),
              ),
            ),
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
    final size = MediaQuery.sizeOf(context);
    final isTablet = size.width >= 600;

    final pagePadding = isTablet
        ? EdgeInsets.symmetric(
            horizontal: size.width >= 1100
                ? 36.0
                : (size.width >= 850 ? 28.0 : 22.0),
            vertical: 24.0,
          )
        : AppInsets.page;

    int libraryColumns;
    double libraryAspectRatio;
    double gridSpacing;

    if (size.width >= 1100) {
      libraryColumns = 6;
      libraryAspectRatio = 0.82;
      gridSpacing = 16.0;
    } else if (size.width >= 850) {
      libraryColumns = 5;
      libraryAspectRatio = 0.82;
      gridSpacing = 14.0;
    } else if (size.width >= 600) {
      libraryColumns = 4;
      libraryAspectRatio = 0.80;
      gridSpacing = 12.0;
    } else {
      libraryColumns = 3;
      libraryAspectRatio = 0.78;
      gridSpacing = 8.w;
    }

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      behavior: HitTestBehavior.translucent,
      child: ListView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: pagePadding,
        children: [
          Text(
            'Explore',
            style: AppTextStyle.headline.copyWith(
              fontSize: isTablet ? 30.0 : null,
            ),
          ),
          (isTablet ? 16.0 : 14.0).verticalSpace,
          AppTextField(
            controller: _searchController,
            validator: AppValidators.none,
            variant: AppTextFieldVariant.search,
            hint: 'Search routines, stretches, body areas',
            onChanged: (value) => setState(() => _query = value),
          ),
          (isTablet ? 16.0 : 14.0).verticalSpace,
          AppCard(
            variant: AppCardVariant.list,
            child: AppSettingRow(
              title: 'Safe for me',
              subtitle:
                  "Hides stretches and routines that don't suit your body",
              showDivider: false,
              trailing: AppSwitch(
                value: _safeForMe,
                semanticLabel: 'Safe for me',
                onChanged: (value) => setState(() => _safeForMe = value),
              ),
            ),
          ),
          (isTablet ? 16.0 : 14.0).verticalSpace,
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
          (isTablet ? 12.0 : 10.0).verticalSpace,
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
          (isTablet ? 24.0 : 20.0).verticalSpace,
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
              if (isTablet && size.width >= 800) {
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: routines.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 14.0,
                    mainAxisSpacing: 12.0,
                    childAspectRatio: size.width >= 1100 ? 4.8 : 4.0,
                  ),
                  itemBuilder: (context, i) =>
                      _ExploreRoutineTile(routine: routines[i]),
                );
              }
              return Column(
                children: [
                  for (var i = 0; i < routines.length; i++) ...[
                    if (i > 0) 10.verticalSpace,
                    _ExploreRoutineTile(routine: routines[i]),
                    if (i == (routines.length > 2 ? 1 : routines.length - 1))
                      const AdNative(small: true),
                  ],
                ],
              );
            },
            loading: () {
              if (isTablet && size.width >= 800) {
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: 4,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 14.0,
                    mainAxisSpacing: 12.0,
                    childAspectRatio: size.width >= 1100 ? 4.8 : 4.0,
                  ),
                  itemBuilder: (context, i) =>
                      const ExploreRoutineCardShimmer(),
                );
              }
              return Column(
                children: [
                  for (var i = 0; i < 5; i++) ...[
                    if (i > 0) 10.verticalSpace,
                    const ExploreRoutineCardShimmer(),
                  ],
                ],
              );
            },
            error: (err, stack) => Padding(
              padding: EdgeInsets.symmetric(vertical: 12.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Failed to load routines from server.',
                    style: AppTextStyle.bodySmall.copyWith(
                      color: colors.danger,
                    ),
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
          (isTablet ? 24.0 : 18.0).verticalSpace,
          const AdNative(small: false),
          (isTablet ? 24.0 : 18.0).verticalSpace,
          Text(
            'Stretch library · ${_isLoadingStretches ? '...' : stretches.length}',
            style: AppTextStyle.sectionTitle.copyWith(
              fontSize: isTablet ? 22.0 : null,
            ),
          ),
          (isTablet ? 14.0 : 10.0).verticalSpace,
          if (_isLoadingStretches)
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: libraryColumns * 2,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: libraryColumns,
                mainAxisSpacing: isTablet ? gridSpacing : 8.h,
                crossAxisSpacing: gridSpacing,
                childAspectRatio: libraryAspectRatio,
              ),
              itemBuilder: (context, index) =>
                  const ExploreLibraryTileShimmer(),
            )
          else if (_stretchesError != null)
            Padding(
              padding: EdgeInsets.symmetric(vertical: 12.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Failed to load stretches from server.',
                    style: AppTextStyle.bodySmall.copyWith(
                      color: colors.danger,
                    ),
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
                crossAxisCount: libraryColumns,
                mainAxisSpacing: isTablet ? gridSpacing : 8.h,
                crossAxisSpacing: gridSpacing,
                childAspectRatio: libraryAspectRatio,
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
    final firstStretch = routine.stretches.isNotEmpty
        ? routine.stretches.first
        : null;
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
              const StretchPlaceholder(),
        ),
      );
    } else {
      thumbnailWidget = const StretchPlaceholder();
    }

    return AppRoutineCard(
      title: routine.name,
      meta: '${routine.durationText} · ${routine.stretches.length} stretches',
      thumbnail: AppThumb(size: AppThumbSize.large, child: thumbnailWidget),
      onTap: () {
        void navigate() {
          if (!context.mounted) return;
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => RoutineDetailScreen(routine: routine),
            ),
          );
        }

        AdService.maybeShowInterstitial(action: 'routine', onClosed: navigate);
      },
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
    final size = MediaQuery.sizeOf(context);
    final isTablet = size.width >= 600;
    final hasThumb =
        stretch.thumbnailUrl != null && stretch.thumbnailUrl!.trim().isNotEmpty;

    final thumbSize = isTablet
        ? (size.width >= 1100 ? 98.0 : (size.width >= 850 ? 92.0 : 88.0))
        : 80.r;
    final thumbRadius =
        isTablet ? BorderRadius.circular(14.0) : AppBorderRadius.md;

    Widget thumbnailWidget;
    if (frameBytes != null) {
      thumbnailWidget = ClipRRect(
        borderRadius: thumbRadius,
        child: Image.memory(
          frameBytes,
          fit: BoxFit.cover,
          gaplessPlayback: true,
        ),
      );
    } else if (hasThumb) {
      thumbnailWidget = ClipRRect(
        borderRadius: thumbRadius,
        child: Image.network(
          stretch.thumbnailUrl!,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) =>
              const StretchPlaceholder(),
        ),
      );
    } else {
      thumbnailWidget = const StretchPlaceholder();
    }

    return Material(
      color: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius:
            isTablet ? BorderRadius.circular(18.0) : AppBorderRadius.xl,
        side: BorderSide(color: colors.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: widget.onTap,
        child: Padding(
          padding: isTablet
              ? const EdgeInsets.symmetric(horizontal: 10.0, vertical: 12.0)
              : EdgeInsets.symmetric(horizontal: 6.w, vertical: 15.h),
          child: Column(
            children: [
              SizedBox(
                width: thumbSize,
                height: thumbSize,
                child: thumbnailWidget,
              ),
              (isTablet ? 10.0 : 5.0).verticalSpace,
              Expanded(
                child: Center(
                  child: Text(
                    stretch.name,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyle.caption.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: isTablet ? 13.5 : null,
                      height: 1.25,
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
