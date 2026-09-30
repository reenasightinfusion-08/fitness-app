import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fitness_app/features/home/models/today_plan.dart';
import 'package:fitness_app/services/routine_service.dart';

/// Provides the singleton [RoutineService] instance.
final routineServiceProvider = Provider<RoutineService>((ref) => RoutineService());

/// Fetches all active routines from the Express backend via [RoutineService.fetchRoutines].
final routinesProvider = FutureProvider<List<RoutineSummary>>((ref) async {
  final service = ref.watch(routineServiceProvider);
  return service.fetchRoutines();
});
