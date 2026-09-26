import 'package:flutter/material.dart';

/// Monday-first day labels, keyed by [DateTime.weekday] (1 = Monday …
/// 7 = Sunday) — matches the prototype's `D` array and its
/// `[1,2,3,4,5,6,0]` display order.
const List<int> weekdayDisplayOrder = [1, 2, 3, 4, 5, 6, 7];
const Map<int, String> weekdayShortLabels = {
  1: 'M',
  2: 'T',
  3: 'W',
  4: 'T',
  5: 'F',
  6: 'S',
  7: 'S',
};
const Map<int, String> weekdayFullLabels = {
  1: 'Monday',
  2: 'Tuesday',
  3: 'Wednesday',
  4: 'Thursday',
  5: 'Friday',
  6: 'Saturday',
  7: 'Sunday',
};

/// A single push-notification reminder — the prototype's `a.reminders[i]`.
@immutable
class ReminderEntry {
  const ReminderEntry({
    required this.id,
    required this.time,
    this.isOn = true,
    this.days = const {1, 2, 3, 4, 5, 6, 7},
  });

  final String id;
  final TimeOfDay time;
  final bool isOn;

  /// [DateTime.weekday] values this reminder fires on.
  final Set<int> days;

  ReminderEntry copyWith({TimeOfDay? time, bool? isOn, Set<int>? days}) =>
      ReminderEntry(
        id: id,
        time: time ?? this.time,
        isOn: isOn ?? this.isOn,
        days: days ?? this.days,
      );
}

/// Desk-break nudges — the prototype's `a.desk`. The work-hours window is
/// fixed in this prototype; only whether it's on and how often is editable.
@immutable
class DeskNudgeSettings {
  const DeskNudgeSettings({
    this.isOn = false,
    this.everyMinutes = 60,
    this.fromLabel = '9:00 am',
    this.toLabel = '6:00 pm',
  });

  final bool isOn;
  final int everyMinutes;
  final String fromLabel;
  final String toLabel;

  DeskNudgeSettings copyWith({bool? isOn, int? everyMinutes}) =>
      DeskNudgeSettings(
        isOn: isOn ?? this.isOn,
        everyMinutes: everyMinutes ?? this.everyMinutes,
        fromLabel: fromLabel,
        toLabel: toLabel,
      );
}

const List<int> deskNudgeIntervalOptions = [45, 60, 90];
