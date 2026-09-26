import 'package:flutter/foundation.dart';

/// How a session is narrated — the prototype's `st.guide` segmented
/// control on `screens.settings`.
enum GuidanceMode { voice, beeps, silent }

const Map<GuidanceMode, String> guidanceModeLabels = {
  GuidanceMode.voice: 'Voice',
  GuidanceMode.beeps: 'Beeps only',
  GuidanceMode.silent: 'Silent',
};

/// Extra time added to every hold, in seconds — stepped by 5, matching
/// the prototype's `holdPlus`.
const int holdStepSeconds = 5;
const int minExtraHoldSeconds = -15;
const int maxExtraHoldSeconds = 30;

/// The prototype's `transExtra` segments: standard, or +5s / +10s per
/// transition.
const List<int> transitionExtraOptions = [0, 5, 10];

/// "My day starts at" — an hour past midnight (0–6), matching the
/// prototype's late-night streak rule.
const List<int> dayStartHourOptions = [0, 1, 2, 3, 4, 5, 6];

String dayStartHourLabel(int hour) =>
    hour == 0 ? '12:00 am (midnight)' : '$hour:00 am';

/// Everything on the Session settings screen — mirrors the prototype's
/// `acct().settings`. There's no backend yet, so this lives only for the
/// session (in-memory, via [sessionSettingsProvider]).
@immutable
class SessionSettings {
  const SessionSettings({
    this.guidance = GuidanceMode.voice,
    this.voiceRate = 1.0,
    this.musicOn = true,
    this.showCalories = false,
    this.extraHoldSeconds = 0,
    this.extraTransitionSeconds = 0,
    this.dayStartHour = 0,
  });

  final GuidanceMode guidance;

  /// 0.7–1.3, in steps of 0.1.
  final double voiceRate;
  final bool musicOn;
  final bool showCalories;
  final int extraHoldSeconds;
  final int extraTransitionSeconds;
  final int dayStartHour;

  SessionSettings copyWith({
    GuidanceMode? guidance,
    double? voiceRate,
    bool? musicOn,
    bool? showCalories,
    int? extraHoldSeconds,
    int? extraTransitionSeconds,
    int? dayStartHour,
  }) => SessionSettings(
    guidance: guidance ?? this.guidance,
    voiceRate: voiceRate ?? this.voiceRate,
    musicOn: musicOn ?? this.musicOn,
    showCalories: showCalories ?? this.showCalories,
    extraHoldSeconds: extraHoldSeconds ?? this.extraHoldSeconds,
    extraTransitionSeconds:
        extraTransitionSeconds ?? this.extraTransitionSeconds,
    dayStartHour: dayStartHour ?? this.dayStartHour,
  );
}
