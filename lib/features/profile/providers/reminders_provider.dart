import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fitness_app/core/providers/auth_service_provider.dart';
import 'package:fitness_app/features/onboarding_setup/providers/onboarding_profile_provider.dart';
import 'package:fitness_app/features/profile/models/reminder.dart';
import 'package:fitness_app/services/reminder_notification_service.dart';

/// The user's stretch reminders. Signed-in accounts load them from the server
/// and every change is saved back and re-scheduled as local notifications on the
/// phone; the sample account keeps its reminders in memory only.
class RemindersController extends Notifier<List<ReminderEntry>> {
  int _nextId = 1;
  bool _loaded = false;
  Future<void> _saving = Future.value();
  Future<void> _loading = Future.value();

  @override
  List<ReminderEntry> build() {
    _nextId = 1;
    _loaded = false;
    _loading = Future.microtask(_load);
    return const [];
  }

  String get _name => ref.read(onboardingProfileProvider).name;

  Future<void> _load() async {
    final auth = ref.read(authServiceProvider);
    if (!await auth.hasSession()) {
      return;
    }
    try {
      final saved = await auth.getReminders();
      state = [
        for (final item in saved)
          ReminderEntry.fromJson('r${_nextId++}', item as Map<String, dynamic>),
      ];
      _loaded = true;
      await ReminderNotificationService.instance.sync(state, name: _name);
    } catch (e) {
      debugPrint('[Reminders] could not load reminders: $e');
    }
  }

  /// The daily reminder picked in the setup wizard becomes the account's first
  /// reminder: shown in Profile, saved to the server and scheduled on the phone.
  Future<void> addFromOnboarding(TimeOfDay time) async {
    await _loading;
    if (state.isNotEmpty) return;
    _loaded = true;
    state = [ReminderEntry(id: 'r${_nextId++}', time: time)];
    _persist();
  }

  void add() {
    state = [
      ...state,
      ReminderEntry(
        id: 'r${_nextId++}',
        time: const TimeOfDay(hour: 8, minute: 0),
      ),
    ];
    _persist();
  }

  void remove(String id) {
    state = state.where((reminder) => reminder.id != id).toList();
    _persist();
  }

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
    _persist();
  }

  /// Schedules the current list on the phone, then saves it to the server.
  /// Runs one at a time, in the order the changes were made.
  void _persist() {
    final snapshot = state;
    _saving = _saving.then((_) async {
      final auth = ref.read(authServiceProvider);
      if (!await auth.hasSession()) return;
      final service = ReminderNotificationService.instance;
      try {
        if (snapshot.any((r) => r.isOn)) await service.requestPermission();
        await service.sync(snapshot, name: _name);
      } catch (e) {
        debugPrint('[Reminders] could not schedule notifications: $e');
      }
      // Never overwrite the server's list with one that failed to load.
      if (!_loaded) return;
      try {
        await auth.saveReminders([for (final r in snapshot) r.toJson()]);
      } catch (e) {
        debugPrint('[Reminders] could not save reminders: $e');
      }
    });
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
