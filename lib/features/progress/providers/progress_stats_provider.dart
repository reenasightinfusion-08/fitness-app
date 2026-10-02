import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fitness_app/core/providers/providers.dart';
import 'package:fitness_app/core/widgets/widgets.dart';
import 'package:fitness_app/features/home/models/active_routine_model.dart';
import 'package:fitness_app/features/profile/providers/session_settings_provider.dart';

/// Streak, weekly minutes, session count and calendar days, all derived from
/// the completed-routine history. A "day" starts at the user's day-start hour,
/// so a session at 2 am with a 5 am start counts for the previous day.
class ProgressStats {
  const ProgressStats({
    this.streakDays = 0,
    this.minutesThisWeek = 0,
    this.totalSessions = 0,
    this.completedDaysThisMonth = const {},
    this.completedDays = const {},
    required this.today,
  });

  factory ProgressStats.fromHistory(
    List<ActiveRoutineModel> history,
    DateTime now,
    int dayStartHour,
  ) {
    DateTime dayOf(DateTime t) {
      final shifted = t.subtract(Duration(hours: dayStartHour));
      return DateTime(shifted.year, shifted.month, shifted.day);
    }

    final today = dayOf(now);
    final weekStart = today.subtract(Duration(days: today.weekday - 1));
    final days = <DateTime>{};
    var minutes = 0;
    var sessions = 0;

    for (final record in history) {
      final completedAt = record.completedAt?.toLocal();
      if (completedAt == null) continue;
      sessions++;
      final day = dayOf(completedAt);
      days.add(day);
      if (!day.isBefore(weekStart) && !day.isAfter(today)) {
        minutes += (record.routine.totalSeconds / 60).round();
      }
    }

    // The streak survives until the end of the day after the last session.
    var cursor = days.contains(today)
        ? today
        : today.subtract(const Duration(days: 1));
    var streak = 0;
    while (days.contains(cursor)) {
      streak++;
      cursor = DateTime(cursor.year, cursor.month, cursor.day - 1);
    }

    return ProgressStats(
      streakDays: streak,
      minutesThisWeek: minutes,
      totalSessions: sessions,
      completedDaysThisMonth: {
        for (final d in days)
          if (d.year == today.year && d.month == today.month) d.day,
      },
      completedDays: days,
      today: today,
    );
  }

  final int streakDays;
  final int minutesThisWeek;
  final int totalSessions;
  final Set<int> completedDaysThisMonth;

  /// Every day (midnight-normalised, after the day-start shift) with a session.
  final Set<DateTime> completedDays;

  /// Today's date after applying the day-start hour.
  final DateTime today;

  /// Monday-first strip for the current week, marking days with a session.
  List<WeekDayModel> weekStrip() {
    const labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    final monday = today.subtract(Duration(days: today.weekday - 1));
    return List.generate(7, (index) {
      final date = DateTime(monday.year, monday.month, monday.day + index);
      return WeekDayModel(
        label: labels[index],
        dayOfMonth: date.day,
        isDone: completedDays.contains(date),
        isToday: date == today,
      );
    });
  }
}

final progressStatsProvider = Provider.autoDispose<ProgressStats>((ref) {
  final history = ref.watch(routineHistoryProvider).valueOrNull ?? const [];
  final dayStartHour = ref.watch(sessionSettingsProvider).dayStartHour;
  return ProgressStats.fromHistory(history, DateTime.now(), dayStartHour);
});
