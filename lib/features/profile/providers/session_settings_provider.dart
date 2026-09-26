import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fitness_app/features/profile/models/session_settings.dart';

class SessionSettingsController extends Notifier<SessionSettings> {
  @override
  SessionSettings build() => const SessionSettings();

  void setGuidance(GuidanceMode mode) =>
      state = state.copyWith(guidance: mode);

  void setVoiceRate(double rate) => state = state.copyWith(voiceRate: rate);

  void setMusicOn(bool value) => state = state.copyWith(musicOn: value);

  void setShowCalories(bool value) =>
      state = state.copyWith(showCalories: value);

  void stepExtraHold(int delta) {
    final next = (state.extraHoldSeconds + delta).clamp(
      minExtraHoldSeconds,
      maxExtraHoldSeconds,
    );
    state = state.copyWith(extraHoldSeconds: next.toInt());
  }

  void setExtraTransition(int seconds) =>
      state = state.copyWith(extraTransitionSeconds: seconds);

  void setDayStartHour(int hour) => state = state.copyWith(dayStartHour: hour);
}

final sessionSettingsProvider =
    NotifierProvider<SessionSettingsController, SessionSettings>(
      SessionSettingsController.new,
    );
