import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fitness_app/core/providers/auth_service_provider.dart';
import 'package:fitness_app/features/home/models/today_plan.dart';
import 'package:fitness_app/services/custom_routine_service.dart';

final customRoutineServiceProvider = Provider<CustomRoutineService>(
  (ref) => CustomRoutineService(ref.watch(authServiceProvider)),
);

/// Routines the signed-in user built in the routine builder, newest first,
/// kept on the server (`/api/custom-routines`). Empty without an account.
///
/// Invalidate this on logout so the next account doesn't see the last one's list.
class CustomRoutinesController extends AsyncNotifier<List<RoutineSummary>> {
  @override
  Future<List<RoutineSummary>> build() async {
    if (!await ref.watch(authServiceProvider).hasSession()) return const [];
    return ref.watch(customRoutineServiceProvider).fetch();
  }

  /// Saves [draft] and returns the stored routine (with its server id), or
  /// null when it was saved but the list couldn't be reloaded. Throws the
  /// server's reason if it wasn't saved, e.g. a duplicate name.
  Future<RoutineSummary?> create(RoutineSummary draft) async {
    final service = ref.read(customRoutineServiceProvider);
    await service.create(draft);
    try {
      final routines = await service.fetch();
      state = AsyncData(routines);
      final name = draft.name.trim();
      return routines.where((routine) => routine.name == name).firstOrNull;
    } catch (_) {
      ref.invalidateSelf();
      return null;
    }
  }

  /// Removes [id] from the list straight away and deletes it on the server,
  /// putting it back and rethrowing if the server says no.
  Future<void> remove(String id) async {
    final previous = state.valueOrNull ?? const <RoutineSummary>[];
    state = AsyncData([
      for (final routine in previous)
        if (routine.id != id) routine,
    ]);
    try {
      await ref.read(customRoutineServiceProvider).delete(id);
    } catch (_) {
      state = AsyncData(previous);
      rethrow;
    }
  }
}

final customRoutinesProvider =
    AsyncNotifierProvider<CustomRoutinesController, List<RoutineSummary>>(
      CustomRoutinesController.new,
    );
