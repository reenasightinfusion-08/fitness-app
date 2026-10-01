import 'package:flutter/foundation.dart';

import 'package:fitness_app/features/home/models/today_plan.dart';

/// Today's routine as the server picked it for this user, plus whether they
/// already finished it today (so the card can say so instead of asking again).
@immutable
class TodaysPlanModel {
  const TodaysPlanModel({required this.routine, required this.completedToday});

  /// The `data` of `GET /api/plans/today` is a routine with one extra flag.
  factory TodaysPlanModel.fromJson(Map<String, dynamic> json) => TodaysPlanModel(
    routine: RoutineSummary.fromJson(json),
    completedToday: json['completedToday'] as bool? ?? false,
  );

  final RoutineSummary routine;
  final bool completedToday;
}
