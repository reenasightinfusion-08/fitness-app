import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fitness_app/features/onboarding_setup/models/onboarding_options.dart';
import 'package:fitness_app/features/onboarding_setup/models/onboarding_profile.dart';

/// Holds the profile the 10-step wizard is filling in. One [OnboardingProfile]
/// replaced wholesale per edit — mirrors the prototype's single mutable
/// `acct().profile`, but each mutation here is a named, typed method rather
/// than the prototype's generic `set(key, value)` dispatch.
class OnboardingProfileController extends Notifier<OnboardingProfile> {
  @override
  OnboardingProfile build() => const OnboardingProfile();

  void loadFromApi(Map<String, dynamic> json) =>
      state = OnboardingProfile.fromUserJson(json);

  void setName(String value) => state = state.copyWith(name: value);

  void setCountry(String value) => state = state.copyWith(country: value);

  void setAge(String value) => state = state.copyWith(age: value);

  void setGender(String value) =>
      state = state.copyWith(gender: () => state.gender == value ? null : value);

  void setHeightCm(String value) => state = state.copyWith(heightCm: value);

  void setWeightKg(String value) => state = state.copyWith(weightKg: value);

  /// Matches the prototype's "skip clears height/weight" behaviour for the
  /// body step.
  void resetHeightWeight() =>
      state = state.copyWith(heightCm: '', weightKg: '');

  void setLifestyle(String id) =>
      state = state.copyWith(lifestyle: () => id);

  void toggleSport(String id) => state = state.copyWith(
    sports: _toggled(state.sports, id),
  );

  /// Capped at [maxGoalPicks] — tapping a third goal is a no-op until one
  /// is deselected, matching the prototype.
  void toggleGoal(String id) {
    final goals = state.goals;
    if (goals.contains(id)) {
      state = state.copyWith(goals: _toggled(goals, id));
    } else if (goals.length < maxGoalPicks) {
      state = state.copyWith(goals: _toggled(goals, id));
    }
  }

  void togglePainArea(String id) => state = state.copyWith(
    painAreas: _toggled(state.painAreas, id),
  );

  void toggleInjuryFlag(String id) {
    switch (id) {
      case 'noKneel':
        state = state.copyWith(noKneel: !state.noKneel);
      case 'noFloor':
        state = state.copyWith(noFloor: !state.noFloor);
      case 'surgery':
        state = state.copyWith(hadRecentSurgery: !state.hadRecentSurgery);
      case 'pregnant':
        state = state.copyWith(isPregnant: !state.isPregnant);
    }
  }

  void setInjurySeverity(String area, InjurySeverity severity) {
    final next = Map<String, InjurySeverity>.from(state.injurySeverity);
    next[area] = severity;
    state = state.copyWith(injurySeverity: next);
  }

  void clearInjurySeverity(String area) {
    final next = Map<String, InjurySeverity>.from(state.injurySeverity);
    next.remove(area);
    state = state.copyWith(injurySeverity: next);
  }

  void toggleEquipment(String id) => state = state.copyWith(
    equipment: _toggled(state.equipment, id),
    equipmentNone: false,
  );

  void setEquipmentNone(bool value) => state = state.copyWith(
    equipmentNone: value,
    equipment: value ? const {} : state.equipment,
  );

  void setFlexAnswer(int index, int score) {
    final next = List<int?>.from(state.flexAnswers);
    next[index] = score;
    state = state.copyWith(flexAnswers: next);
  }

  void setMinutesPerDay(int minutes) =>
      state = state.copyWith(minutesPerDay: minutes);

  void setTimeOfDay(String value) => state = state.copyWith(
    timeOfDay: () => state.timeOfDay == value ? null : value,
  );

  void setReminderOn(bool value) => state = state.copyWith(reminderOn: value);

  void setReminderTime(TimeOfDay value) =>
      state = state.copyWith(reminderTime: value);

  void setSafetyAcknowledged(bool value) =>
      state = state.copyWith(safetyAcknowledged: value);

  Set<String> _toggled(Set<String> current, String id) => current.contains(id)
      ? (Set<String>.from(current)..remove(id))
      : (Set<String>.from(current)..add(id));
}

/// Shapes an [OnboardingProfile] into the JSON body `PATCH /api/users/me`
/// expects — matches the flat field set on the backend's User schema.
extension OnboardingProfileApi on OnboardingProfile {
  Map<String, dynamic> toUserUpdate({bool markComplete = false}) => {
    'name': name,
    'country': country,
    'age': int.tryParse(age),
    'gender': gender,
    'heightCm': int.tryParse(heightCm),
    'weightKg': int.tryParse(weightKg),
    'lifestyle': lifestyle,
    'sports': sports.toList(),
    'goals': goals.toList(),
    'painAreas': painAreas.toList(),
    'noKneel': noKneel,
    'noFloor': noFloor,
    'hadRecentSurgery': hadRecentSurgery,
    'isPregnant': isPregnant,
    'injurySeverity': injurySeverity.map((k, v) => MapEntry(k, v.name)),
    'equipment': equipment.toList(),
    'equipmentNone': equipmentNone,
    'flexAnswers': [
      for (var i = 0; i < flexAnswers.length; i++)
        if (flexAnswers[i] != null)
          {
            'question': flexibilityQuestions[i].question,
            'answer': flexibilityQuestions[i]
                .options
                .firstWhere((o) => o.score == flexAnswers[i])
                .label,
            'score': flexAnswers[i],
          },
    ],
    'flexibilityLevel': calcFlexibilityLevel(flexAnswers),
    'minutesPerDay': minutesPerDay,
    'timeOfDay': timeOfDay,
    'reminderOn': reminderOn,
    'reminderTime': {'hour': reminderTime.hour, 'minute': reminderTime.minute},
    'safetyAcknowledged': safetyAcknowledged,
    if (markComplete) 'onboardingComplete': true,
  };
}

final onboardingProfileProvider =
    NotifierProvider<OnboardingProfileController, OnboardingProfile>(
      OnboardingProfileController.new,
    );
