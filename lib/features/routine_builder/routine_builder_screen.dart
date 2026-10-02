import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:fitness_app/core/providers/providers.dart';
import 'package:fitness_app/core/theme/theme.dart';
import 'package:fitness_app/core/utils/app_validators.dart';
import 'package:fitness_app/core/widgets/widgets.dart';
import 'package:fitness_app/features/explore/models/explore_data.dart';
import 'package:fitness_app/features/get_ready/get_ready_screen.dart';
import 'package:fitness_app/features/home/models/today_plan.dart';
import 'package:fitness_app/features/home/widgets/stretch_thumbnail.dart';
import 'package:fitness_app/features/stretch_detail/models/stretch_model.dart';
import 'package:fitness_app/services/auth_service.dart';
import 'package:fitness_app/services/stretch_service.dart' show StretchServiceException;

/// Matches the prototype's `screens.builder`: name a routine, add stretches
/// from the library, drag to reorder and tune each hold time, then save —
/// it is stored on the server and lands in the Mine tab's "Built by you"
/// section, or goes straight into Get ready with "Save & start".
class RoutineBuilderScreen extends ConsumerStatefulWidget {
  const RoutineBuilderScreen({super.key, this.initialRoutine});

  /// When set, the builder opens pre-filled with a copy of this routine —
  /// the prototype's "Customise a copy" flow (`B={name: r.name+' (my
  /// version)', items: r.items...}`).
  final RoutineSummary? initialRoutine;

  @override
  ConsumerState<RoutineBuilderScreen> createState() =>
      _RoutineBuilderScreenState();
}

class _RoutineBuilderScreenState extends ConsumerState<RoutineBuilderScreen> {
  static const _minHold = 10;
  static const _maxHold = 90;
  static const _holdStep = 5;
  static const _minReps = 1;
  static const _maxReps = 5;

  static const _transitionOptions = [
    AppSegmentModel<int?>(value: null, label: 'Auto'),
    AppSegmentModel<int?>(value: 5, label: '5s'),
    AppSegmentModel<int?>(value: 10, label: '10s'),
    AppSegmentModel<int?>(value: 15, label: '15s'),
  ];

  late final _nameController = TextEditingController(text: _initialName);
  late final List<StretchPreview> _items = List.of(
    widget.initialRoutine?.stretches ?? const [],
  );
  late int? _transitionSeconds = widget.initialRoutine?.transitionSeconds;
  bool _isSaving = false;
  bool _startAfterSave = false;

  String get _initialName {
    final source = widget.initialRoutine;
    if (source == null) return '';
    return '${source.name} (my version)';
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  int get _totalSeconds =>
      _items.fold(0, (sum, item) => sum + item.totalHoldSeconds);

  Future<void> _openPicker() async {
    final existingNames = _items.map((item) => item.name).toSet();
    final picked = await AppBottomSheet.show<List<StretchModel>>(
      context,
      isScrollable: true,
      child: _StretchPickerSheet(excludeNames: existingNames),
    );
    if (picked == null || picked.isEmpty) return;
    setState(() {
      _items.addAll([
        for (final stretch in picked)
          stretch.toPreview().copyWith(model: stretch),
      ]);
    });
  }

  void _reorder(int oldIndex, int newIndex) => setState(() {
    if (newIndex > oldIndex) newIndex -= 1;
    _items.insert(newIndex, _items.removeAt(oldIndex));
  });

  void _adjustHold(int index, int delta) => setState(() {
    final next = (_items[index].holdSeconds + delta).clamp(
      _minHold,
      _maxHold,
    );
    _items[index] = _items[index].copyWith(holdSeconds: next);
  });

  void _adjustReps(int index, int delta) => setState(() {
    final next = (_items[index].repCount + delta).clamp(_minReps, _maxReps);
    _items[index] = _items[index].copyWith(repCount: next);
  });

  void _removeAt(int index) => setState(() => _items.removeAt(index));

  RoutineSummary? _buildRoutine() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      AppSnackBar.show(context, 'Give your routine a name.');
      return null;
    }
    if (_items.isEmpty) {
      AppSnackBar.show(context, 'Add at least one stretch first.');
      return null;
    }
    return RoutineSummary(
      name: name,
      minutes: (_totalSeconds / 60).ceil().clamp(1, 999),
      equipmentLabel: 'None',
      stretches: List.of(_items),
      transitionSeconds: _transitionSeconds,
    );
  }

  /// Saves the routine on the server. With [startAfter], goes on to Get ready
  /// using the stored routine (its server id is what lets progress be saved).
  Future<void> _submit({required bool startAfter}) async {
    final draft = _buildRoutine();
    if (draft == null || _isSaving) return;
    setState(() {
      _isSaving = true;
      _startAfterSave = startAfter;
    });

    final RoutineSummary? saved;
    try {
      saved = await ref.read(customRoutinesProvider.notifier).create(draft);
    } catch (error) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      AppSnackBar.showError(
        context,
        error is AuthException
            ? error.message
            : "Couldn't save your routine. Try again.",
      );
      return;
    }
    if (!mounted) return;

    final navigator = Navigator.of(context);
    if (startAfter && saved != null) {
      final plan = saved;
      navigator.pushReplacement(
        MaterialPageRoute(
          builder: (_) => GetReadyScreen(plan: plan, routineType: 'custom'),
        ),
      );
      return;
    }
    navigator.pop();
    AppSnackBar.showSuccess(context, 'Routine saved.');
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.ground,
      appBar: AppTopBar(
        title: 'New routine',
        onBack: () => Navigator.of(context).pop(),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: AppInsets.page,
                children: [
                  AppTextField(
                    controller: _nameController,
                    validator: AppValidators.none,
                    label: 'Name',
                    hint: 'e.g. Post-run hips',
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.done,
                  ),
                  20.verticalSpace,
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          'Stretches · ${_items.length}',
                          style: AppTextStyle.sectionTitle,
                        ),
                      ),
                      if (_items.isNotEmpty)
                        Padding(
                          padding: EdgeInsets.only(top: 4.h),
                          child: Text(
                            '${(_totalSeconds / 60).ceil()} min total',
                            style: AppTextStyle.meta.copyWith(
                              color: colors.ink2,
                            ),
                          ),
                        ),
                    ],
                  ),
                  4.verticalSpace,
                  Text(
                    'Drag the handle to reorder. They play in exactly this order.',
                    style: AppTextStyle.meta.copyWith(color: colors.ink2),
                  ),
                  10.verticalSpace,
                  if (_items.isEmpty)
                    const AppEmptyState(
                      icon: Icons.self_improvement_rounded,
                      title: 'No stretches yet',
                      message: 'Add a few to get started.',
                    )
                  else
                    ReorderableListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      buildDefaultDragHandles: false,
                      itemCount: _items.length,
                      onReorder: _reorder,
                      itemBuilder: (context, index) => _BuilderItemTile(
                        key: ValueKey('${_items[index].name}-$index'),
                        index: index,
                        item: _items[index],
                        onHoldDecrement: () => _adjustHold(index, -_holdStep),
                        onHoldIncrement: () => _adjustHold(index, _holdStep),
                        onRepsDecrement: () => _adjustReps(index, -1),
                        onRepsIncrement: () => _adjustReps(index, 1),
                        onRemove: () => _removeAt(index),
                      ),
                    ),
                  14.verticalSpace,
                  AppButton(
                    label: 'Add stretches',
                    icon: Icons.add_rounded,
                    variant: AppButtonVariant.secondary,
                    onPressed: _openPicker,
                  ),
                  20.verticalSpace,
                  const AppFieldLabel(text: 'Time to get into each stretch'),
                  8.verticalSpace,
                  AppSegmentedControl<int?>(
                    segments: _transitionOptions,
                    value: _transitionSeconds,
                    onChanged: (value) =>
                        setState(() => _transitionSeconds = value),
                  ),
                  6.verticalSpace,
                  Text(
                    'Auto gives more time when you move from standing to '
                    'the floor.',
                    style: AppTextStyle.meta.copyWith(color: colors.ink2),
                  ),
                ],
              ),
            ),
            AppBottomActionBar(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: AppButton(
                        label: 'Save',
                        variant: AppButtonVariant.secondary,
                        isLoading: _isSaving && !_startAfterSave,
                        onPressed: _isSaving
                            ? null
                            : () => _submit(startAfter: false),
                      ),
                    ),
                    10.horizontalSpace,
                    Expanded(
                      child: AppButton(
                        label: 'Save & start',
                        icon: Icons.play_arrow_rounded,
                        isLoading: _isSaving && _startAfterSave,
                        onPressed: _items.isEmpty || _isSaving
                            ? null
                            : () => _submit(startAfter: true),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// One row in the builder's stretch list — thumb, name, hold-time stepper
/// and a remove button, dragged by its handle to reorder.
class _BuilderItemTile extends StatelessWidget {
  const _BuilderItemTile({
    super.key,
    required this.index,
    required this.item,
    required this.onHoldDecrement,
    required this.onHoldIncrement,
    required this.onRepsDecrement,
    required this.onRepsIncrement,
    required this.onRemove,
  });

  final int index;
  final StretchPreview item;
  final VoidCallback onHoldDecrement;
  final VoidCallback onHoldIncrement;
  final VoidCallback onRepsDecrement;
  final VoidCallback onRepsIncrement;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Material(
        color: colors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: AppBorderRadius.xl,
          side: BorderSide(color: colors.line),
        ),
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: EdgeInsets.all(10.r),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ReorderableDragStartListener(
                index: index,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 2.w),
                  child: Icon(
                    Icons.drag_indicator_rounded,
                    size: 20.r,
                    color: colors.ink3,
                  ),
                ),
              ),
              6.horizontalSpace,
              StretchThumbnail(stretch: item, size: AppThumbSize.small),
              10.horizontalSpace,
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text.rich(
                      TextSpan(
                        text: item.name,
                        children: [
                          if (item.isEachSide)
                            TextSpan(
                              text: '  · each side',
                              style: AppTextStyle.meta.copyWith(
                                color: colors.ink2,
                              ),
                            ),
                        ],
                      ),
                      style: AppTextStyle.titleMedium,
                    ),
                    6.verticalSpace,
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Row(
                        children: [
                          AppStepper(
                           isTransparent: true,
                            valueLabel: '${item.holdSeconds}s',
                            onDecrement: item.holdSeconds <= 10
                                ? null
                                : onHoldDecrement,
                            onIncrement: item.holdSeconds >= 90
                                ? null
                                : onHoldIncrement,
                          ),
                          6.horizontalSpace,
                          AppStepper(
                           isTransparent: true,
                            valueLabel: '×${item.repCount}',
                            onDecrement: item.repCount <= 1
                                ? null
                                : onRepsDecrement,
                            onIncrement: item.repCount >= 5
                                ? null
                                : onRepsIncrement,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              AppIconButton(
                icon: Icons.close_rounded,
                tooltip: 'Remove ${item.name}',
                onPressed: onRemove,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Matches the prototype's `pickerList()` sheet: search, an area filter,
/// and a checkable list of stretches to add — the real library from
/// [stretchesProvider], since saved routines reference stretches by id.
class _StretchPickerSheet extends ConsumerStatefulWidget {
  const _StretchPickerSheet({required this.excludeNames});

  /// Names already in the routine being built, hidden so they can't be
  /// added twice.
  final Set<String> excludeNames;

  @override
  ConsumerState<_StretchPickerSheet> createState() =>
      _StretchPickerSheetState();
}

class _StretchPickerSheetState extends ConsumerState<_StretchPickerSheet> {
  final _searchController = TextEditingController();
  String _query = '';
  String? _area;
  final Set<String> _selected = {};

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<StretchModel> _filtered(List<StretchModel> library) {
    final query = _query.trim().toLowerCase();
    return library.where((stretch) {
      if (widget.excludeNames.contains(stretch.name)) return false;
      if (_area != null && !stretch.areas.contains(_area)) return false;
      if (query.isEmpty) return true;
      return stretch.name.toLowerCase().contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final library = ref.watch(stretchesProvider);
    final results = _filtered(library.valueOrNull ?? const []);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Add stretches', style: AppTextStyle.titleLarge),
        14.verticalSpace,
        AppTextField(
          controller: _searchController,
          validator: AppValidators.none,
          variant: AppTextFieldVariant.search,
          hint: 'Search stretches',
          onChanged: (value) => setState(() => _query = value),
        ),
        12.verticalSpace,
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
        14.verticalSpace,
        if (library.isLoading)
          Padding(
            padding: EdgeInsets.symmetric(vertical: 24.h),
            child: const Center(child: AppLoader()),
          )
        else if (library.hasError)
          AppEmptyState(
            icon: Icons.cloud_off_rounded,
            title: "Couldn't load stretches",
            message: library.error is StretchServiceException
                ? library.error.toString()
                : 'Check your connection and try again.',
            actionLabel: 'Try again',
            onAction: () => ref.invalidate(stretchesProvider),
          )
        else if (results.isEmpty)
          const AppEmptyState(
            icon: Icons.search_off_rounded,
            title: 'No stretches match',
            message: 'Try a different search or area.',
          )
        else
          for (final stretch in results)
            _PickerRow(
              stretch: stretch,
              isSelected: _selected.contains(stretch.id),
              onTap: () => setState(() {
                if (!_selected.remove(stretch.id)) {
                  _selected.add(stretch.id);
                }
              }),
            ),
        18.verticalSpace,
        AppButton(
          label: _selected.isEmpty
              ? 'Add stretches'
              : 'Add ${_selected.length} '
                    'stretch${_selected.length == 1 ? '' : 'es'}',
          onPressed: _selected.isEmpty
              ? null
              : () => Navigator.of(context).pop(<StretchModel>[
                  for (final stretch
                      in library.valueOrNull ?? const <StretchModel>[])
                    if (_selected.contains(stretch.id)) stretch,
                ]),
        ),
      ],
    );
  }
}

class _PickerRow extends StatelessWidget {
  const _PickerRow({
    required this.stretch,
    required this.isSelected,
    required this.onTap,
  });

  final StretchModel stretch;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Semantics(
      button: true,
      selected: isSelected,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppBorderRadius.md,
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 8.h),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 24.r,
                  height: 24.r,
                  decoration: BoxDecoration(
                    color: isSelected ? colors.accent : Colors.transparent,
                    border: Border.all(
                      color: isSelected ? colors.accent : colors.line,
                      width: 2,
                    ),
                    borderRadius: AppBorderRadius.xs,
                  ),
                  child: isSelected
                      ? Icon(
                          Icons.check_rounded,
                          size: 16.r,
                          color: colors.accentInk,
                        )
                      : null,
                ),
                10.horizontalSpace,
                StretchThumbnail(
                  stretch: stretch.toPreview().copyWith(model: stretch),
                  size: AppThumbSize.small,
                ),
                10.horizontalSpace,
                Expanded(
                  child: Text(stretch.name, style: AppTextStyle.titleMedium),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
