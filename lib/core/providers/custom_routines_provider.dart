import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fitness_app/features/home/models/today_plan.dart';

/// Routines built in the routine builder — the prototype's `a.routines`.
/// Keyed by [RoutineSummary.name], same as [favoritesProvider]: there's no
/// backend yet, so names stand in for stable ids.
class CustomRoutinesController extends Notifier<List<RoutineSummary>> {
  @override
  List<RoutineSummary> build() => [];

  void add(RoutineSummary routine) => state = [...state, routine];

  void remove(String name) =>
      state = state.where((routine) => routine.name != name).toList();
}

final customRoutinesProvider =
    NotifierProvider<CustomRoutinesController, List<RoutineSummary>>(
      CustomRoutinesController.new,
    );
