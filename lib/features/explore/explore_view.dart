import 'package:flutter/material.dart';

import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:fitness_app/core/theme/theme.dart';
import 'package:fitness_app/core/utils/app_validators.dart';
import 'package:fitness_app/core/widgets/widgets.dart';
import 'package:fitness_app/features/explore/models/explore_data.dart';
import 'package:fitness_app/features/routine_detail/routine_detail_screen.dart';
import 'package:fitness_app/features/stretch_detail/models/stretch_model.dart';
import 'package:fitness_app/features/stretch_detail/stretch_detail_sheet.dart';
import 'package:fitness_app/services/stretch_service.dart';

/// Matches the prototype's `screens.explore`: search, a "Safe for me"
/// toggle, area/time filter chips, matching routine cards and the full
/// stretch library.
class ExploreView extends StatefulWidget {
  const ExploreView({super.key});

  @override
  State<ExploreView> createState() => _ExploreViewState();
}

class _ExploreViewState extends State<ExploreView> {
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

  bool _matchesQuery(String name, List<String> areaKeys) {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return true;
    if (name.toLowerCase().contains(q)) return true;
    return areaKeys.any(
      (key) => ExploreDemoData.areas
          .firstWhere((a) => a.key == key, orElse: () => ExploreArea(key, key))
          .label
          .toLowerCase()
          .contains(q),
    );
  }

  List<ExploreRoutine> get _filteredRoutines => ExploreDemoData.routines
      .where((r) => _matchesQuery(r.name, r.areas))
      .where((r) => _area == null || r.areas.contains(_area))
      .where((r) => _time.matches(r.minutes))
      .toList();

  List<StretchModel> get _filteredStretches => _apiStretches
      .where((s) => _matchesQuery(s.name, s.areas))
      .where((s) => _area == null || s.areas.contains(_area))
      .toList();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final routines = _filteredRoutines;
    final stretches = _filteredStretches;

    return ListView(
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
            subtitle: "Swaps out stretches that don't suit your body",
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
        if (routines.isEmpty)
          const AppEmptyState(
            icon: Icons.search_off_rounded,
            title: 'No routines match',
            message: 'Try a different area or time.',
          )
        else
          for (var i = 0; i < routines.length; i++) ...[
            if (i > 0) 10.verticalSpace,
            AppRoutineCard(
              title: routines[i].name,
              meta: routines[i].meta,
              isLocked: routines[i].isPremium,
              thumbnail: AppThumb(
                size: AppThumbSize.large,
                child: StretchFigure(pose: routines[i].previewPose),
              ),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => RoutineDetailScreen(
                    routine: routines[i].toRoutineSummary(),
                  ),
                ),
              ),
            ),
          ],
        24.verticalSpace,
        Text(
          'Stretch library · ${_isLoadingStretches ? '...' : stretches.length}',
          style: AppTextStyle.sectionTitle,
        ),
        10.verticalSpace,
        if (_isLoadingStretches)
          Padding(
            padding: EdgeInsets.symmetric(vertical: 24.h),
            child: const Center(child: CircularProgressIndicator()),
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
    );
  }
}

/// Mirrors the prototype's `.tile`: a centered thumbnail + name, three to
/// a row — distinct from [AppTileCard], which is left-aligned with a meta
/// line for "Quick picks".
class _LibraryTile extends StatelessWidget {
  const _LibraryTile({required this.stretch, required this.onTap});

  final StretchModel stretch;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final hasThumb =
        stretch.thumbnailUrl != null && stretch.thumbnailUrl!.trim().isNotEmpty;

    return Material(
      color: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: AppBorderRadius.xl,
        side: BorderSide(color: colors.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 16.h),
          child: Column(
            children: [
              SizedBox(
                width: 80.r,
                height: 80.r,
                child: hasThumb
                    ? ClipRRect(
                        borderRadius: AppBorderRadius.md,
                        child: Image.network(
                          stretch.thumbnailUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              StretchFigure(pose: stretch.pose),
                        ),
                      )
                    : StretchFigure(pose: stretch.pose),
              ),
              6.verticalSpace,
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
