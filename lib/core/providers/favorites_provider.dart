import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Favourited routines, keyed by [RoutineSummary.name] (there's no backend
/// yet, so names stand in for stable ids — mirrors the prototype's
/// `a.favorites` array of routine ids). Read by the Mine tab's Favourites
/// section and toggled from the routine detail screen's heart button.
class FavoritesController extends Notifier<Set<String>> {
  @override
  Set<String> build() => {};

  bool isFavorite(String routineId) => state.contains(routineId);

  void toggle(String routineId) {
    final next = {...state};
    if (!next.remove(routineId)) next.add(routineId);
    state = next;
  }
}

final favoritesProvider = NotifierProvider<FavoritesController, Set<String>>(
  FavoritesController.new,
);
