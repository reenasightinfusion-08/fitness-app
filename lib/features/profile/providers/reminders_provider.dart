import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fitness_app/features/profile/models/reminder.dart';

/// Demo reminders so the screen isn't empty on first run — mirrors the
/// prototype's seeded 8:00 am / 9:00 pm account.
List<ReminderEntry> _seedReminders() => [
  const ReminderEntry(id: 'r1', time: TimeOfDay(hour: 8, minute: 0)),
  const ReminderEntry(id: 'r2', time: TimeOfDay(hour: 21, minute: 0)),
];

class RemindersController extends Notifier<List<ReminderEntry>> {
  int _nextId = 3;

  @override
  List<ReminderEntry> build() => _seedReminders();

  void add() => state = [
    ...state,
    ReminderEntry(id: 'r${_nextId++}', time: const TimeOfDay(hour: 8, minute: 0)),
  ];

  void remove(String id) =>
      state = state.where((reminder) => reminder.id != id).toList();

  void toggleOn(String id) => _update(id, (r) => r.copyWith(isOn: !r.isOn));

  void setTime(String id, TimeOfDay time) =>
      _update(id, (r) => r.copyWith(time: time));

  void toggleDay(String id, int weekday) => _update(id, (r) {
    final days = Set<int>.from(r.days);
    if (!days.remove(weekday)) days.add(weekday);
    return r.copyWith(days: days);
  });

  void _update(String id, ReminderEntry Function(ReminderEntry) update) {
    state = [
      for (final reminder in state)
        if (reminder.id == id) update(reminder) else reminder,
    ];
  }
}

final remindersProvider =
    NotifierProvider<RemindersController, List<ReminderEntry>>(
      RemindersController.new,
    );

class DeskNudgeController extends Notifier<DeskNudgeSettings> {
  @override
  DeskNudgeSettings build() => const DeskNudgeSettings();

  void setOn(bool value) => state = state.copyWith(isOn: value);

  void setEveryMinutes(int minutes) =>
      state = state.copyWith(everyMinutes: minutes);
}

final deskNudgeProvider =
    NotifierProvider<DeskNudgeController, DeskNudgeSettings>(
      DeskNudgeController.new,
    );
