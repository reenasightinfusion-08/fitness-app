import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// How the session narrates itself — mirrors the prototype's
/// `settings.guide`. Lives here (not in a feature folder) so both the
/// Get Ready screen and the session player can share one source of truth.
enum GuideMode { voice, beeps, silent }

/// The five moments the session player narrates — mirrors the prototype's
/// `cue(kind, text)` call sites in `announce()`/`tick()`.
enum CueKind { start, switchSides, ten, count, trans }

/// Ports the web prototype's Web Audio SFX/ambient-drone/TTS cues to
/// Flutter, and its guide-mode routing (`cue()` in the prototype): voice
/// speaks the moment, beeps plays a tone for it, silent taps a haptic.
///
/// The web version fires every tone from a fresh oscillator node, so cues
/// can freely overlap — a "3-2-1" tick landing while the previous cue is
/// still ringing is normal there. A single shared [AudioPlayer] can't do
/// that: reusing one player for every cue makes each `play()` call stop
/// and reload whatever the previous cue was mid-sound, so fast-arriving
/// cues (count ticks right before the next stretch's transition tone)
/// clipped or silently dropped. Each one-shot cue gets its own
/// pre-loaded player instead, so triggering it never races another cue's
/// asset load.
class AudioService {
  AudioService._();
  static final AudioService instance = AudioService._();

  static const _sfxNames = ['start', 'switch', 'ten', 'count', 'trans', 'gong'];

  final Map<String, AudioPlayer> _sfx = {
    for (final name in _sfxNames) name: AudioPlayer(playerId: 'sfx_$name'),
  };
  final AudioPlayer _music = AudioPlayer(playerId: 'music');
  final FlutterTts _tts = FlutterTts();

  bool _initialized = false;
  bool _musicOn = false;
  final double _musicVolume = 0.15; // subtle, mirrors the original's quiet ramp to .04 gain
  final double _duckedVolume = 0.04;
  double _currentVolume = 0; // audioplayers has no getVolume(), so track it ourselves
  int _fadeGen = 0; // cancels a stale fade when a newer one (or a stop) supersedes it

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    await _music.setReleaseMode(ReleaseMode.loop);
    await Future.wait([
      for (final entry in _sfx.entries)
        entry.value
            .setReleaseMode(ReleaseMode.stop)
            .then((_) => entry.value.setSourceAsset('audio/sfx_${entry.key}.wav')),
    ]);
    await _tts.awaitSpeakCompletion(true);
  }

  // --- one-shot SFX, matches the tone()-based cues in the original ---
  Future<void> _play(String name) async {
    final player = _sfx[name];
    if (player == null) return;
    try {
      await player.seek(Duration.zero);
      await player.resume();
    } catch (_) {
      try {
        await player.play(AssetSource('audio/sfx_$name.wav'));
      } catch (_) {}
    }
  }

  Future<void> start() => _play('start');
  Future<void> switchCue() => _play('switch');
  Future<void> ten() => _play('ten');
  Future<void> count() => _play('count');
  Future<void> trans() => _play('trans');
  Future<void> gong() => _play('gong');

  // --- ambient drone loop, matches startMusic()/stopMusic() ---
  Future<void> startMusic() async {
    if (_musicOn) return;
    _musicOn = true;
    _currentVolume = 0;
    await _music.setVolume(0);
    await _music.play(AssetSource('audio/music_drone_loop.wav'));
    unawaited(_fadeMusicTo(_musicVolume, const Duration(milliseconds: 2500)));
  }

  Future<void> stopMusic() async {
    if (!_musicOn) return;
    _musicOn = false;
    await _fadeMusicTo(0, const Duration(milliseconds: 400));
    await _music.stop();
  }

  /// Lower music under speech, matches duck() in the original.
  Future<void> duck(bool on) async {
    if (!_musicOn) return;
    await _fadeMusicTo(on ? _duckedVolume : _musicVolume, const Duration(milliseconds: 150));
  }

  /// Each call gets its own generation number; a call that's superseded by
  /// a newer one (duck(true) immediately followed by duck(false), or a
  /// stopMusic() landing mid duck-in) notices its generation is stale and
  /// stops adjusting volume, instead of the two fades fighting over the
  /// player's volume for the next several steps.
  Future<void> _fadeMusicTo(double target, Duration duration) async {
    final gen = ++_fadeGen;
    const steps = 12;
    final start = _currentVolume;
    final step = (target - start) / steps;
    for (var i = 1; i <= steps; i++) {
      await Future.delayed(duration ~/ steps);
      if (gen != _fadeGen) return;
      _currentVolume = start + step * i;
      try {
        await _music.setVolume(_currentVolume);
      } catch (_) {}
    }
  }

  // --- TTS, matches speak() ---
  Future<void> speak(String text, {double rate = 1.0}) async {
    await duck(true);
    await _tts.setSpeechRate((0.5 * rate).clamp(0.3, 0.7));
    try {
      await _tts.speak(text);
    } catch (_) {}
    await duck(false);
  }

  /// Cuts off whatever [speak] is currently saying — e.g. the Settings
  /// screen's "Test the voice" button, tapped again while it's talking.
  /// Safe to call even when nothing is speaking.
  Future<void> stopSpeaking() async {
    try {
      await _tts.stop();
    } catch (_) {}
    await duck(false);
  }

  Future<void> _vibrate(List<void Function()> pulses, {int gapMs = 90}) async {
    for (var i = 0; i < pulses.length; i++) {
      try {
        pulses[i]();
      } catch (_) {}
      if (i < pulses.length - 1) await Future.delayed(Duration(milliseconds: gapMs));
    }
  }

  /// Routes one narrated moment through whichever [GuideMode] the person
  /// picked on the Get Ready screen — a direct port of the prototype's
  /// `cue(kind, text)`: voice speaks [text] (count still just ticks),
  /// beeps plays the matching tone, silent taps a haptic instead.
  Future<void> cue(CueKind kind, {String? text, required GuideMode mode, double rate = 1.0}) {
    switch (mode) {
      case GuideMode.voice:
        if (kind == CueKind.count) return count();
        if (text != null && text.isNotEmpty) return speak(text, rate: rate);
        return Future.value();
      case GuideMode.beeps:
        switch (kind) {
          case CueKind.start:
            return start();
          case CueKind.switchSides:
            return switchCue();
          case CueKind.ten:
            return ten();
          case CueKind.count:
            return count();
          case CueKind.trans:
            return trans();
        }
      case GuideMode.silent:
        switch (kind) {
          case CueKind.start:
            return _vibrate([HapticFeedback.mediumImpact]);
          case CueKind.switchSides:
            return _vibrate([HapticFeedback.lightImpact, HapticFeedback.lightImpact]);
          case CueKind.ten:
            return _vibrate([HapticFeedback.lightImpact]);
          case CueKind.count:
            return _vibrate([HapticFeedback.selectionClick]);
          case CueKind.trans:
            return _vibrate([HapticFeedback.heavyImpact]);
        }
    }
  }

  Future<void> dispose() async {
    for (final player in _sfx.values) {
      await player.dispose();
    }
    await _music.dispose();
    await _tts.stop();
  }
}
