import 'package:flutter/material.dart';

/// How hard an injury flares up — mirrors the prototype's per-injury
/// severity segmented control.
enum InjurySeverity { mild, moderate, serious }

/// Everything the 10-step setup wizard collects, mirroring the
/// prototype's `acct().profile` object. Immutable — the provider holds
/// one of these and replaces it wholesale via [copyWith].
@immutable
class OnboardingProfile {
  const OnboardingProfile({
    this.name = '',
    this.email = '',
    this.country = '',
    this.age = '',
    this.gender,
    this.heightCm = '',
    this.weightKg = '',
    this.lifestyle,
    this.sports = const {},
    this.goals = const {},
    this.painAreas = const {},
    this.noKneel = false,
    this.noFloor = false,
    this.hadRecentSurgery = false,
    this.isPregnant = false,
    this.injurySeverity = const {},
    this.equipment = const {},
    this.equipmentNone = false,
    this.flexAnswers = const [null, null, null],
    this.minutesPerDay = 10,
    this.timeOfDay,
    this.reminderOn = true,
    this.reminderTime = const TimeOfDay(hour: 8, minute: 0),
    this.safetyAcknowledged = false,
  });

  final String name;
  final String email;
  final String country;
  final String age;
  final String? gender;
  final String heightCm;
  final String weightKg;

  /// A [LifestyleOption.id].
  final String? lifestyle;
  final Set<String> sports;

  /// [GoalOption.id]s, capped at two (enforced by the controller).
  final Set<String> goals;

  /// Body-area keys from [painAreaLabels].
  final Set<String> painAreas;

  final bool noKneel;
  final bool noFloor;
  final bool hadRecentSurgery;
  final bool isPregnant;

  /// Injury-area keys from [injuryAreaLabels] to how badly they flare up.
  final Map<String, InjurySeverity> injurySeverity;

  /// Equipment keys from [equipmentLabels].
  final Set<String> equipment;
  final bool equipmentNone;

  /// One answer per [flexibilityQuestions] entry, in order.
  final List<int?> flexAnswers;

  final int minutesPerDay;
  final String? timeOfDay;
  final bool reminderOn;
  final TimeOfDay reminderTime;
  final bool safetyAcknowledged;

  OnboardingProfile copyWith({
    String? name,
    String? email,
    String? country,
    String? age,
    String? Function()? gender,
    String? heightCm,
    String? weightKg,
    String? Function()? lifestyle,
    Set<String>? sports,
    Set<String>? goals,
    Set<String>? painAreas,
    bool? noKneel,
    bool? noFloor,
    bool? hadRecentSurgery,
    bool? isPregnant,
    Map<String, InjurySeverity>? injurySeverity,
    Set<String>? equipment,
    bool? equipmentNone,
    List<int?>? flexAnswers,
    int? minutesPerDay,
    String? Function()? timeOfDay,
    bool? reminderOn,
    TimeOfDay? reminderTime,
    bool? safetyAcknowledged,
  }) => OnboardingProfile(
    name: name ?? this.name,
    email: email ?? this.email,
    country: country ?? this.country,
    age: age ?? this.age,
    gender: gender == null ? this.gender : gender(),
    heightCm: heightCm ?? this.heightCm,
    weightKg: weightKg ?? this.weightKg,
    lifestyle: lifestyle == null ? this.lifestyle : lifestyle(),
    sports: sports ?? this.sports,
    goals: goals ?? this.goals,
    painAreas: painAreas ?? this.painAreas,
    noKneel: noKneel ?? this.noKneel,
    noFloor: noFloor ?? this.noFloor,
    hadRecentSurgery: hadRecentSurgery ?? this.hadRecentSurgery,
    isPregnant: isPregnant ?? this.isPregnant,
    injurySeverity: injurySeverity ?? this.injurySeverity,
    equipment: equipment ?? this.equipment,
    equipmentNone: equipmentNone ?? this.equipmentNone,
    flexAnswers: flexAnswers ?? this.flexAnswers,
    minutesPerDay: minutesPerDay ?? this.minutesPerDay,
    timeOfDay: timeOfDay == null ? this.timeOfDay : timeOfDay(),
    reminderOn: reminderOn ?? this.reminderOn,
    reminderTime: reminderTime ?? this.reminderTime,
    safetyAcknowledged: safetyAcknowledged ?? this.safetyAcknowledged,
  );

  factory OnboardingProfile.fromUserJson(Map<String, dynamic> json) {
    TimeOfDay reminderTime = const TimeOfDay(hour: 8, minute: 0);
    if (json['reminderTime'] is Map) {
      final rMap = json['reminderTime'] as Map;
      if (rMap['hour'] != null && rMap['minute'] != null) {
        reminderTime = TimeOfDay(
          hour: rMap['hour'] as int,
          minute: rMap['minute'] as int,
        );
      }
    }

    final rawInjury = json['injurySeverity'];
    final injurySeverity = <String, InjurySeverity>{};
    if (rawInjury is Map) {
      rawInjury.forEach((k, v) {
        final severity = InjurySeverity.values.firstWhere(
          (s) => s.name == v,
          orElse: () => InjurySeverity.mild,
        );
        injurySeverity[k.toString()] = severity;
      });
    }

    List<int?> flexAnswers = const [null, null, null];
    if (json['flexAnswers'] is List) {
      final list = json['flexAnswers'] as List;
      final parsed = List<int?>.filled(3, null);
      for (var i = 0; i < list.length && i < 3; i++) {
        if (list[i] is Map && list[i]['score'] is int) {
          parsed[i] = list[i]['score'] as int;
        }
      }
      flexAnswers = parsed;
    }

    return OnboardingProfile(
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      country: json['country']?.toString() ?? '',
      age: json['age']?.toString() ?? '',
      gender: json['gender']?.toString(),
      heightCm: json['heightCm']?.toString() ?? '',
      weightKg: json['weightKg']?.toString() ?? '',
      lifestyle: json['lifestyle']?.toString(),
      sports: (json['sports'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toSet() ??
          const {},
      goals: (json['goals'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toSet() ??
          const {},
      painAreas: (json['painAreas'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toSet() ??
          const {},
      noKneel: json['noKneel'] == true,
      noFloor: json['noFloor'] == true,
      hadRecentSurgery: json['hadRecentSurgery'] == true,
      isPregnant: json['isPregnant'] == true,
      injurySeverity: injurySeverity,
      equipment: (json['equipment'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toSet() ??
          const {},
      equipmentNone: json['equipmentNone'] == true,
      flexAnswers: flexAnswers,
      minutesPerDay: json['minutesPerDay'] as int? ?? 10,
      timeOfDay: json['timeOfDay']?.toString(),
      reminderOn: json['reminderOn'] != false,
      reminderTime: reminderTime,
      safetyAcknowledged: json['safetyAcknowledged'] == true,
    );
  }
}

/// The prototype's `calcLevel()`: three 0–2 scores add up to a 1–3
/// starting level (Beginner/Intermediate/Advanced).
int calcFlexibilityLevel(List<int?> answers) {
  if (answers.any((value) => value == null)) return 1;
  final total = answers.fold<int>(0, (sum, value) => sum + (value ?? 0));
  if (total <= 2) return 1;
  if (total <= 4) return 2;
  return 3;
}

const List<String> flexibilityLevelLabels = [
  '',
  'Beginner',
  'Intermediate',
  'Advanced',
];
