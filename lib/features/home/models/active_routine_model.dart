import 'package:flutter/foundation.dart';

import 'package:fitness_app/features/home/models/today_plan.dart';

/// Called by the session player each time the user reaches a new stretch, with
/// how many stretches are already done (2 means they are on the third). Lets
/// the server remember where to resume without the player knowing about it.
typedef StretchProgressCallback = void Function(int completedStretch);

/// A routine the user has begun, as `GET /api/active-routines/current` returns
/// it: the routine as it was when they began, and how far they got.
@immutable
class ActiveRoutineModel {
  const ActiveRoutineModel({
    required this.id,
    required this.routineType,
    required this.routineId,
    required this.routine,
    required this.completedStretch,
    required this.source,
    this.completedAt,
  });

  factory ActiveRoutineModel.fromJson(Map<String, dynamic> json) {
    final parsed = RoutineSummary.fromJson(json);
    final routineId = json['routineId'] as String?;
    return ActiveRoutineModel(
      id: json['_id'] as String,
      routineType: json['routineType'] as String? ?? 'system',
      routineId: routineId,
      routine: RoutineSummary(
        id: routineId,
        name: json['routineName'] as String? ?? parsed.name,
        stretches: parsed.stretches,
        totalSeconds: parsed.stretches.fold(
          0,
          (sum, stretch) => sum + stretch.totalHoldSeconds,
        ),
      ),
      completedStretch: json['completedStretch'] as int? ?? 0,
      source: json['source'] as String? ?? 'user',
      completedAt: json['completedAt'] == null
          ? null
          : DateTime.tryParse(json['completedAt'] as String),
    );
  }

  /// The active-routine record's own id, used to save progress.
  final String id;

  /// 'system' or 'custom'.
  final String routineType;

  /// The source routine's id; with [routineType] it says which routine this is.
  final String? routineId;

  final RoutineSummary routine;

  /// Stretches already done; also the index of the stretch to resume at.
  final int completedStretch;

  /// 'plan' = started from today's plan card; 'user' = picked by the user.
  final String source;

  /// When the user finished the routine (completed records only).
  final DateTime? completedAt;

  /// The stretch the user will do next, or null when none are left.
  StretchPreview? get nextStretch => completedStretch < routine.stretches.length
      ? routine.stretches[completedStretch]
      : null;
}
