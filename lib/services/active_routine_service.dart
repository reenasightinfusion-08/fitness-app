import 'package:flutter/foundation.dart';

import 'package:fitness_app/features/home/models/active_routine_model.dart';
import 'package:fitness_app/features/home/models/today_plan.dart';
import 'package:fitness_app/services/auth_service.dart';

/// Begins routines and keeps their progress on the server, so a session that is
/// left half-way can be resumed from the same stretch later.
class ActiveRoutineService {
  ActiveRoutineService(this.authService);

  final AuthService authService;

  /// Every routine the user has begun and not finished, latest activity first.
  Future<List<ActiveRoutineModel>> current() async {
    final data = await authService.getCurrentRoutines();
    return data
        .map((json) => ActiveRoutineModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Begins [routine] (or finds it already in progress) and returns its record.
  ///
  /// Returns null when the routine has no server id (a demo or unsaved routine)
  /// or the server can't be reached: the session still plays, it just can't be
  /// resumed. [source] is 'plan' when started from today's plan card.
  Future<ActiveRoutineModel?> start({
    required RoutineSummary routine,
    String routineType = 'system',
    String source = 'user',
  }) async {
    final routineId = routine.id;
    if (routineId == null) return null;
    try {
      await authService.beginRoutine(
        routineId: routineId,
        routineType: routineType,
        source: source,
      );
      final all = await current();
      for (final active in all) {
        if (active.routineId == routineId && active.routineType == routineType) {
          return active;
        }
      }
    } catch (e) {
      debugPrint('[ActiveRoutineService] could not begin routine: $e');
    }
    return null;
  }

  /// Saves how many stretches are done. Failures are only logged: losing one
  /// save must never interrupt a session in progress.
  Future<void> saveProgress(String id, int completedStretch) async {
    try {
      await authService.saveRoutineProgress(id, completedStretch);
    } catch (e) {
      debugPrint('[ActiveRoutineService] could not save progress: $e');
    }
  }
}
