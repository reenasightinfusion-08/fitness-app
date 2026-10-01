import 'package:flutter/foundation.dart';

import 'package:fitness_app/features/home/models/today_plan.dart';

/// One day of the user's plan: which routine they do on it.
@immutable
class PlanDayModel {
  const PlanDayModel({
    required this.day,
    required this.isToday,
    required this.routine,
    this.reason = '',
  });

  factory PlanDayModel.fromJson(Map<String, dynamic> json) => PlanDayModel(
    day: json['day'] as int? ?? 1,
    isToday: json['isToday'] as bool? ?? false,
    reason: json['reason'] as String? ?? '',
    routine: RoutineSummary.fromJson(json['routine'] as Map<String, dynamic>),
  );

  /// 1-based position in the plan.
  final int day;
  final bool isToday;
  final RoutineSummary routine;

  /// Why this routine is on the plan, in terms of the user's own answers.
  /// Empty when the plan was built by fixed rules.
  final String reason;
}

/// The whole plan the server built from the onboarding answers: a routine per
/// day that repeats, shown once after onboarding.
@immutable
class PlanOverviewModel {
  const PlanOverviewModel({required this.days, this.summary = ''});

  factory PlanOverviewModel.fromJson(Map<String, dynamic> json) =>
      PlanOverviewModel(
        summary: json['summary'] as String? ?? '',
        days: (json['days'] as List? ?? [])
            .map((day) => PlanDayModel.fromJson(day as Map<String, dynamic>))
            .toList(),
      );

  final List<PlanDayModel> days;

  /// What the plan is for, in a sentence or two. Empty for rule-built plans.
  final String summary;

  int get planDays => days.length;

  PlanDayModel get today =>
      days.firstWhere((day) => day.isToday, orElse: () => days.first);
}
