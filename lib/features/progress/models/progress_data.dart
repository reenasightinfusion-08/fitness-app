import 'package:flutter/foundation.dart';

/// One finished session, as shown in Progress > History.
@immutable
class SessionSummary {
  const SessionSummary({
    required this.title,
    required this.date,
    required this.stretchCount,
    required this.minutes,
  });

  final String title;
  final DateTime date;
  final int stretchCount;
  final int minutes;
}

/// Demo content for the Progress screen — there's no backend yet, so this
/// stands in for what a real sessions/streak service would return.
class ProgressDemoData {
  const ProgressDemoData._();

  static const currentStreakDays = 4;
  static const minutesThisWeek = 46;
  static const totalSessions = 27;
  static const flexibilityLevel = 'Intermediate';

  static List<SessionSummary> sessions(DateTime now) => [
    SessionSummary(
      title: 'Morning reset',
      date: now,
      stretchCount: 5,
      minutes: 12,
    ),
    SessionSummary(
      title: 'Desk break',
      date: now.subtract(const Duration(days: 1)),
      stretchCount: 4,
      minutes: 5,
    ),
    SessionSummary(
      title: 'Bedtime wind-down',
      date: now.subtract(const Duration(days: 2)),
      stretchCount: 6,
      minutes: 10,
    ),
    SessionSummary(
      title: 'Morning reset',
      date: now.subtract(const Duration(days: 3)),
      stretchCount: 5,
      minutes: 12,
    ),
    SessionSummary(
      title: 'After a workout',
      date: now.subtract(const Duration(days: 6)),
      stretchCount: 5,
      minutes: 12,
    ),
  ];

  /// Completed day-of-month numbers for the current streak, standing in
  /// for real session history in this month's calendar.
  static Set<int> completedDaysInMonth(DateTime now) => {
    for (var d = now.day; d > now.day - currentStreakDays && d > 0; d--) d,
  };
}
