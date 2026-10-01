import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fitness_app/core/providers/auth_service_provider.dart';
import 'package:fitness_app/core/providers/todays_plan_provider.dart';
import 'package:fitness_app/features/home/models/active_routine_model.dart';
import 'package:fitness_app/features/home/models/today_plan.dart';
import 'package:fitness_app/features/home/models/todays_plan_model.dart';
import 'package:fitness_app/services/active_routine_history_service.dart';
import 'package:fitness_app/services/active_routine_service.dart';

import 'package:fitness_app/core/providers/todays_plan_provider.dart';

final activeRoutineServiceProvider = Provider<ActiveRoutineService>(
  (ref) => ActiveRoutineService(ref.watch(authServiceProvider)),
);

/// Routines the user began and hasn't finished, newest activity first. Empty
/// without an account ("Explore with a sample account"), where nothing is saved.
final currentRoutinesProvider =
    FutureProvider.autoDispose<List<ActiveRoutineModel>>((ref) async {
      if (!await ref.watch(authServiceProvider).hasSession()) return const [];
      return ref.watch(activeRoutineServiceProvider).current();
    });

/// The active record for today's plan routine, if the user has one in progress.
/// Lets the Today card show Resume / Completed instead of just Start.
final todaysPlanActiveProvider = FutureProvider.autoDispose<ActiveRoutineModel?>(
  (ref) async {
    final plan = await ref.watch(todaysPlanProvider.future).catchError(
      (_) => const TodaysPlanModel(
        routine: TodayDemoData.todaysPlan,
        completedToday: false,
      ),
    );
    final planRoutineId = plan.routine.id;
    if (planRoutineId == null) return null;
    final active = await ref.watch(currentRoutinesProvider.future);
    for (final record in active) {
      if (record.routineId == planRoutineId && record.routineType == 'system') {
        return record;
      }
    }
    return null;
  },
);

/// Routines the user began from the library (source 'user') and hasn't finished,
/// newest activity first — everything the Mine tab's "Incomplete routines" and
/// the Today paused banner draw from.
final pausedUserRoutinesProvider =
    FutureProvider.autoDispose<List<ActiveRoutineModel>>((ref) async {
      final active = await ref.watch(currentRoutinesProvider.future);
      return active.where((r) => r.source == 'user').toList();
    });

/// Completed routines for the Progress history. Empty for the sample account.
final routineHistoryServiceProvider = Provider<ActiveRoutineHistoryService>(
  (ref) => ActiveRoutineHistoryService(ref.watch(authServiceProvider)),
);

final routineHistoryProvider =
    FutureProvider.autoDispose<List<ActiveRoutineModel>>((ref) async {
      if (!await ref.watch(authServiceProvider).hasSession()) return const [];
      return ref.watch(routineHistoryServiceProvider).history();
    });

/// Begins [routine] and returns the callback the session player should call as
/// the user moves through it, or null when progress can't be saved (see
/// [ActiveRoutineService.start]).
///
/// Takes a [ProviderContainer] rather than a ref because the screen that starts
/// a session is replaced by the player, so its own ref is gone by the time the
/// first stretch is reached.
Future<StretchProgressCallback?> beginTrackedRoutine(
  ProviderContainer container,
  RoutineSummary routine, {
  String routineType = 'system',
  String source = 'user',
}) async {
  final service = container.read(activeRoutineServiceProvider);
  final active = await service.start(
    routine: routine,
    routineType: routineType,
    source: source,
  );
  return active == null ? null : trackProgress(container, active);
}

/// The player callback for a routine that is already begun (resuming one).
///
/// Saves are queued so they reach the server in the order they happened, and
/// the Resume banner and today's "done" state refresh after each one.
StretchProgressCallback trackProgress(
  ProviderContainer container,
  ActiveRoutineModel active,
) {
  final service = container.read(activeRoutineServiceProvider);
  final total = active.routine.stretches.length;
  var queue = Future<void>.value();
  return (completedStretch) {
    queue = queue.then((_) async {
      await service.saveProgress(active.id, completedStretch);
      container.invalidate(currentRoutinesProvider);
      container.invalidate(routineHistoryProvider);
      if (completedStretch >= total) container.invalidate(todaysPlanProvider);
    });
  };
}
