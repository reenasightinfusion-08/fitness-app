import 'package:flutter/foundation.dart';

/// How a session is narrated — the prototype's `st.guide` segmented
/// control on `screens.settings`.
enum GuidanceMode { voice, beeps, silent }

const Map<GuidanceMode, String> guidanceModeLabels = {
  GuidanceMode.voice: 'Voice',
  GuidanceMode.beeps: 'Beeps only',
  GuidanceMode.silent: 'Silent',
};

/// "My day starts at" — an hour past midnight (0–6), matching the
/// prototype's late-night streak rule.
const List<int> dayStartHourOptions = [0, 1, 2, 3, 4, 5, 6];

String dayStartHourLabel(int hour) =>
    hour == 0 ? '12:00 am (midnight)' : '$hour:00 am';

/// Everything on the Session settings screen. Kept on the user's account
/// (`sessionSettings` on `/api/users/me`) so it follows them across devices.
@immutable
class SessionSettings {
  const SessionSettings({
    this.guidance = GuidanceMode.voice,
    this.voiceRate = 1.0,
    this.musicOn = true,
    this.showCalories = false,
    this.dayStartHour = 0,
  });

  factory SessionSettings.fromJson(Map<String, dynamic> json) {
    final guidance = GuidanceMode.values.firstWhere(
      (mode) => mode.name == json['guidance'],
      orElse: () => GuidanceMode.voice,
    );
    final rate = (json['voiceRate'] as num?)?.toDouble() ?? 1.0;
    final dayStart = (json['dayStartHour'] as num?)?.toInt() ?? 0;
    return SessionSettings(
      guidance: guidance,
      voiceRate: rate.clamp(0.7, 1.3).toDouble(),
      musicOn: json['musicOn'] != false,
      showCalories: json['showCalories'] == true,
      dayStartHour: dayStart.clamp(0, 6).toInt(),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is SessionSettings &&
      other.guidance == guidance &&
      other.voiceRate == voiceRate &&
      other.musicOn == musicOn &&
      other.showCalories == showCalories &&
      other.dayStartHour == dayStartHour;

  @override
  int get hashCode =>
      Object.hash(guidance, voiceRate, musicOn, showCalories, dayStartHour);

  Map<String, dynamic> toJson() => {
    'guidance': guidance.name,
    'voiceRate': double.parse(voiceRate.toStringAsFixed(1)),
    'musicOn': musicOn,
    'showCalories': showCalories,
    'dayStartHour': dayStartHour,
  };

  final GuidanceMode guidance;

  /// 0.7–1.3, in steps of 0.1.
  final double voiceRate;
  final bool musicOn;
  final bool showCalories;
  final int dayStartHour;

  SessionSettings copyWith({
    GuidanceMode? guidance,
    double? voiceRate,
    bool? musicOn,
    bool? showCalories,
    int? dayStartHour,
  }) => SessionSettings(
    guidance: guidance ?? this.guidance,
    voiceRate: voiceRate ?? this.voiceRate,
    musicOn: musicOn ?? this.musicOn,
    showCalories: showCalories ?? this.showCalories,
    dayStartHour: dayStartHour ?? this.dayStartHour,
  );
}
