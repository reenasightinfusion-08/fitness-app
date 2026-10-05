import 'dart:async';

import 'package:flutter/material.dart';

import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:fitness_app/core/theme/theme.dart';
import 'package:fitness_app/core/widgets/widgets.dart';
import 'package:fitness_app/features/home/models/active_routine_model.dart';
import 'package:fitness_app/features/home/models/today_plan.dart';
import 'package:fitness_app/features/session_complete/session_complete_screen.dart';
import 'package:fitness_app/features/session_player/widgets/stretch_media_player.dart';
import 'package:fitness_app/features/stretch_detail/models/stretch_guide.dart';
import 'package:fitness_app/features/stretch_detail/stretch_detail_sheet.dart';
import 'package:fitness_app/services/audio_service.dart';

enum _StepKind { getReady, hold, switchSides }

/// One beat of the session: a transition, a hold, or the pause between
/// sides. Mirrors the prototype's `buildSteps()`.
class _SessionStep {
  const _SessionStep({
    required this.kind,
    required this.stretchIndex,
    required this.durationSeconds,
    this.side,
  });

  final _StepKind kind;
  final int stretchIndex;
  final int durationSeconds;

  /// 'First' / 'Second' when the stretch is done each side, else null.
  final String? side;
}

/// Seconds to get into stretch [index]. A routine with its own time (builder's
/// "Time to get into each stretch") always uses it. On Auto the first stretch
/// gets 8s, then 6s when the position stays the same, 15s between standing and
/// the floor, and 10s for any other change.
int _getReadySeconds(RoutineSummary plan, int index) {
  final fixed = plan.transitionSeconds;
  if (fixed != null && fixed > 0) return fixed;
  if (index == 0) return 8;
  final from = plan.stretches[index - 1].position;
  final to = plan.stretches[index].position;
  if (from == to) return 6;
  final standingToFloor =
      {from, to}.containsAll({StretchPosition.standing, StretchPosition.floor});
  return standingToFloor ? 15 : 10;
}

List<_SessionStep> _buildSteps(RoutineSummary plan, int? holdOverride) {
  final steps = <_SessionStep>[];
  for (var i = 0; i < plan.stretches.length; i++) {
    final stretch = plan.stretches[i];
    final hold = holdOverride ?? stretch.holdSeconds;
    steps.add(
      _SessionStep(
        kind: _StepKind.getReady,
        stretchIndex: i,
        durationSeconds: _getReadySeconds(plan, i),
      ),
    );
    if (stretch.isEachSide) {
      steps.add(
        _SessionStep(
          kind: _StepKind.hold,
          stretchIndex: i,
          durationSeconds: hold,
          side: 'First',
        ),
      );
      steps.add(
        _SessionStep(
          kind: _StepKind.switchSides,
          stretchIndex: i,
          durationSeconds: 5,
        ),
      );
      steps.add(
        _SessionStep(
          kind: _StepKind.hold,
          stretchIndex: i,
          durationSeconds: hold,
          side: 'Second',
        ),
      );
    } else {
      steps.add(
        _SessionStep(
          kind: _StepKind.hold,
          stretchIndex: i,
          durationSeconds: hold,
        ),
      );
    }
  }
  return steps;
}

String _phaseLabel(_SessionStep step, bool isFirstStretch) =>
    switch (step.kind) {
      _StepKind.getReady => isFirstStretch ? 'Get ready' : 'Get into position',
      _StepKind.switchSides => 'Switch sides',
      _StepKind.hold => 'Hold',
    };

String _formatSeconds(int seconds) {
  final m = seconds ~/ 60;
  final s = seconds % 60;
  return '$m:${s.toString().padLeft(2, '0')}';
}

/// Matches the prototype's `screens.player`: the always-dark session
/// screen that walks through a routine one hold at a time.
class SessionPlayerScreen extends StatefulWidget {
  const SessionPlayerScreen({
    super.key,
    required this.plan,
    this.holdSecondsOverride,
    this.guideMode = GuideMode.voice,
    this.musicOn = true,
    this.voiceRate = 1.0,
    this.startStretchIndex = 0,
    this.onProgress,
  });

  final RoutineSummary plan;

  /// Overrides every stretch's hold time for this session — the "Hold
  /// time" stepper on the Get Ready screen.
  final int? holdSecondsOverride;

  /// Voice / beeps / silent, picked on the Get Ready screen — routes every
  /// cue this screen fires through [AudioService.cue].
  final GuideMode guideMode;

  /// Whether to start the calm background drone for this session.
  final bool musicOn;

  /// How fast the voice speaks, from Session settings (0.7–1.3).
  final double voiceRate;

  /// Which stretch to begin at: 0 for a fresh session, or the number of
  /// stretches already done when resuming a paused one.
  final int startStretchIndex;

  /// Told how many stretches are done each time the user reaches a new one, and
  /// the full count at the end, so the server can resume or complete the routine.
  final StretchProgressCallback? onProgress;

  @override
  State<SessionPlayerScreen> createState() => SessionPlayerScreenState();
}

class SessionPlayerScreenState extends State<SessionPlayerScreen> {
  late final List<_SessionStep> steps = _buildSteps(
    widget.plan,
    widget.holdSecondsOverride,
  );
  late int stepIndex = startStepIndex();
  late int remaining = steps[stepIndex].durationSeconds;
  bool paused = false;
  Timer? _ticker;
  bool _tenFired = false;
  bool _announcePending = false;

  /// A per-session working copy of the plan's stretches, so "Swap" can
  /// replace one stretch for this session without mutating [widget.plan]
  /// itself — mirrors the prototype's `S.items[st.i]={...}`.
  late final List<StretchPreview> _stretches = List.of(widget.plan.stretches);

  /// The first beat of the stretch to resume at, or the very start when that
  /// stretch doesn't exist (e.g. the routine changed since it was saved).
  int startStepIndex() {
    final index = steps.indexWhere(
      (step) => step.stretchIndex == widget.startStretchIndex,
    );
    return index < 0 ? 0 : index;
  }

  /// Reports that every stretch before the current one is done. Called on
  /// entering a stretch (not on every beat), so a save happens once per stretch.
  void reportProgress() => widget.onProgress?.call(currentStep.stretchIndex);

  _SessionStep get currentStep => steps[stepIndex];
  StretchPreview get currentStretch => _stretches[currentStep.stretchIndex];

  int get _totalSeconds =>
      steps.fold(0, (sum, step) => sum + step.durationSeconds);
  int get _elapsedSeconds =>
      steps.take(stepIndex).fold(0, (sum, step) => sum + step.durationSeconds) +
      (currentStep.durationSeconds - remaining);

  @override
  void initState() {
    super.initState();
    reportProgress();
    _startTicker();
    unawaited(_prepareAudio());
  }

  /// Preloads every SFX asset before the first cue tries to play it, so
  /// that first cue doesn't race the asset load and get skipped.
  Future<void> _prepareAudio() async {
    await AudioService.instance.init();
    if (!mounted) return;
    if (widget.musicOn) AudioService.instance.startMusic();
    _announceStep();
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (paused) return;
      setState(() {
        if (remaining > 1) {
          remaining -= 1;
          _checkCountdownCues();
        } else {
          _advance();
        }
      });
    });
  }

  /// Ten-seconds-left and 3-2-1 cues, matching the prototype's `tick()`.
  void _checkCountdownCues() {
    final step = currentStep;
    if (step.kind == _StepKind.hold &&
        step.durationSeconds >= 20 &&
        remaining <= 10 &&
        !_tenFired) {
      _tenFired = true;
      AudioService.instance.cue(
        CueKind.ten,
        text: 'Ten seconds.',
        mode: widget.guideMode,
        rate: widget.voiceRate,
      );
    }
    if (remaining <= 3 && remaining >= 1) {
      AudioService.instance.cue(CueKind.count, mode: widget.guideMode);
    }
  }

  /// Narrates entering the current step, matching the prototype's
  /// `announce()`: a "get ready" beat names the next stretch and reads its
  /// setup cue, a hold beat says which side (if any) and whether to move
  /// or stay still, a switch beat just says "Switch sides."
  void _announceStep() {
    _tenFired = false;
    if (widget.musicOn) AudioService.instance.keepMusicPlaying();
    if (paused) {
      AudioService.instance.stopSpeaking();
      _announcePending = true;
      return;
    }
    final step = currentStep;
    final stretch = currentStretch;
    switch (step.kind) {
      case _StepKind.getReady:
        final pos = step.stretchIndex == 0
            ? 'Get ready. First up: ${stretch.name}.'
            : 'Next: ${stretch.name}.';
        AudioService.instance.cue(
          CueKind.trans,
          text: '$pos ${stretch.setupCue}',
          mode: widget.guideMode,
        rate: widget.voiceRate,
        );
        break;
      case _StepKind.hold:
        final isDynamic =
            StretchLibrary.guideFor(stretch.pose)?.isDynamic ?? false;
        final text =
            (step.side != null ? '${step.side} side. ' : '') +
            (isDynamic
                ? 'Start moving. Breathe with it.'
                : 'Hold, and breathe.');
        AudioService.instance.cue(
          CueKind.start,
          text: text,
          mode: widget.guideMode,
        rate: widget.voiceRate,
        );
        break;
      case _StepKind.switchSides:
        AudioService.instance.cue(
          CueKind.switchSides,
          text: 'Switch sides.',
          mode: widget.guideMode,
        rate: widget.voiceRate,
        );
        break;
    }
  }

  void _advance() {
    if (stepIndex >= steps.length - 1) {
      _finish();
      return;
    }
    final previousStretch = currentStep.stretchIndex;
    stepIndex += 1;
    remaining = steps[stepIndex].durationSeconds;
    if (currentStep.stretchIndex != previousStretch) reportProgress();
    _announceStep();
  }

  void _goBack() {
    setState(() {
      final previousStretch = currentStep.stretchIndex;
      stepIndex = stepIndex > 0 ? stepIndex - 1 : 0;
      remaining = steps[stepIndex].durationSeconds;
      if (currentStep.stretchIndex != previousStretch) reportProgress();
      _announceStep();
    });
  }

  void _finish() {
    _ticker?.cancel();
    widget.onProgress?.call(_stretches.length);
    AudioService.instance.stopMusic();
    AudioService.instance.gong();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => SessionCompleteScreen(plan: widget.plan),
      ),
    );
  }

  void _exit() {
    AudioService.instance.stopSpeaking();
    AudioService.instance.stopMusic();
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  void _togglePause() => _setPaused(!paused);

  /// Single entry point for pausing, so the timer, video, voice and music
  /// always stop and resume together.
  void _setPaused(bool value) {
    if (paused == value) return;
    setState(() => paused = value);
    if (value) {
      AudioService.instance.pauseAll();
    } else {
      unawaited(_resumeAudio());
    }
  }

  Future<void> _resumeAudio() async {
    await AudioService.instance.resumeAll();
    if (!mounted || paused || !_announcePending) return;
    _announcePending = false;
    _announceStep();
  }

  void _addFifteen() => setState(() => remaining += 15);

  /// Swaps between First and Second side for two-sided stretches.
  void _toggleSide() {
    final step = currentStep;
    final stretch = currentStretch;
    if (step.kind != _StepKind.hold || !stretch.isEachSide) return;

    final targetSide = step.side == 'Second' ? 'First' : 'Second';
    final targetIndex = steps.indexWhere(
      (s) =>
          s.stretchIndex == step.stretchIndex &&
          s.kind == _StepKind.hold &&
          s.side == targetSide,
    );

    if (targetIndex != -1) {
      setState(() {
        stepIndex = targetIndex;
        remaining = steps[stepIndex].durationSeconds;
        _announceStep();
      });
    }
  }

  /// Pauses the timer (like tapping pause) while the stretch-info sheet is
  /// open, then restores whatever the pause state was before — mirrors the
  /// prototype's `stretchInfo()`.
  void _showStretchInfo() {
    final wasPaused = paused;
    _setPaused(true);
    StretchDetailSheet.open(
      context,
      name: currentStretch.name,
      pose: currentStretch.pose,
      model: currentStretch.model,
      note: 'Timer paused while you read.',
    ).then((_) {
      if (!mounted || wasPaused) return;
      _setPaused(false);
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    AudioService.instance.stopSpeaking();
    AudioService.instance.stopMusic();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final step = currentStep;
    final stretch = currentStretch;
    final isSwapEnabled = step.kind == _StepKind.hold && stretch.isEachSide;
    final isFirstStretch = step.stretchIndex == 0;
    final nextStretch = step.stretchIndex + 1 < _stretches.length
        ? _stretches[step.stretchIndex + 1]
        : null;

    final stretchThumbUrl = stretch.model?.thumbnailUrl;

    final nextThumbUrl = nextStretch?.model?.thumbnailUrl;
    final hasNextThumb = nextThumbUrl != null && nextThumbUrl.trim().isNotEmpty;

    final cue = switch (step.kind) {
      _StepKind.getReady => stretch.setupCue,
      _StepKind.switchSides =>
        'Slowly come out, then set up on the other side.',
      _StepKind.hold => stretch.feelCue ?? 'Hold, and breathe.',
    };

    return Scaffold(
      backgroundColor: colors.playerBg,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(14.w, 6.h, 14.w, 16.h),
          child: Column(
            children: [
              Row(
                children: [
                  AppIconButton(
                    icon: Icons.close_rounded,
                    tooltip: 'End session',
                    isOnDark: true,
                    onPressed: _exit,
                  ),
                  8.horizontalSpace,
                  Expanded(
                    child: AppSegmentProgress(
                      total: _stretches.length,
                      currentIndex: step.stretchIndex,
                    ),
                  ),
                  8.horizontalSpace,
                  AppIconButton(
                    icon: Icons.info_outline_rounded,
                    tooltip: 'How to do this stretch',
                    isOnDark: true,
                    onPressed: _showStretchInfo,
                  ),
                ],
              ),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      step.side == null
                          ? _phaseLabel(step, isFirstStretch).toUpperCase()
                          : '${_phaseLabel(step, isFirstStretch).toUpperCase()} · ${step.side} side',
                      style: AppTextStyle.eyebrow.copyWith(
                        color: colors.playerDim,
                      ),
                    ),
                    2.verticalSpace,
                    Text(
                      stretch.name,
                      style: AppTextStyle.headline.copyWith(
                        color: colors.playerInk,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    12.verticalSpace,
                    ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: 350.w),
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: ColoredBox(
                          color: Color(0xffEFEBE5),
                          child: ClipRRect(
                            borderRadius: AppBorderRadius.hero,
                            child: Transform.flip(
                              flipX: stretch.isEachSide && step.side == 'Second',
                              child: StretchMediaPlayer(
                                videoUrl: stretch.model?.videoUrl,
                                thumbnailUrl: stretchThumbUrl,
                                pose: stretch.pose,
                                showVideo: step.kind == _StepKind.hold,
                                playing: !paused,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Text(
                      _formatSeconds(remaining),
                      style: AppTextStyle.timer.copyWith(
                        color: colors.playerInk,
                        fontSize: 80
                      ),
                    ),
                    8.verticalSpace,
                    ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: 260.w),
                      child: Text(
                        cue,
                        textAlign: TextAlign.center,
                        style: AppTextStyle.bodySmall.copyWith(
                          color: colors.playerDim,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.all(12.r),
                decoration: BoxDecoration(
                  color: colors.playerInk.withValues(alpha: 0.07),
                  borderRadius: AppBorderRadius.xl,
                ),
                child: Row(
                  children: [
                    AppThumb(
                      isOnDark: true,
                      child: nextStretch == null
                          ? null
                          : (hasNextThumb
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(8.r),
                                    child: Image.network(
                                      nextThumbUrl,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) =>
                                              CustomPaint(
                                                painter: StretchFigurePainter(
                                                  pose: nextStretch.pose,
                                                  nearColor: colors.playerInk,
                                                  farColor: colors.playerDim,
                                                  groundColor:
                                                      Colors.transparent,
                                                  showGround: false,
                                                ),
                                              ),
                                    ),
                                  )
                                : CustomPaint(
                                    painter: StretchFigurePainter(
                                      pose: nextStretch.pose,
                                      nearColor: colors.playerInk,
                                      farColor: colors.playerDim,
                                      groundColor: Colors.transparent,
                                      showGround: false,
                                    ),
                                  )),
                    ),
                    12.horizontalSpace,
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            nextStretch == null ? 'Last stretch' : 'Next up',
                            style: AppTextStyle.caption.copyWith(
                              color: colors.playerDim,
                            ),
                          ),
                          Text(
                            nextStretch?.name ?? 'Almost done',
                            style: AppTextStyle.titleSmall.copyWith(
                              color: colors.playerInk,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              14.verticalSpace,
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  AppPlayerButton(
                    icon: Icons.skip_previous_rounded,
                    tooltip: 'Back',
                    onTap: _goBack,
                  ),
                  AppPlayerButton(
                    icon: Icons.swap_horiz_rounded,
                    tooltip: isSwapEnabled
                        ? 'Swap side'
                        : 'Swap side (only active during two-sided stretch)',
                    label: 'Swap',
                    onTap: isSwapEnabled ? _toggleSide : null,
                  ),
                  AppPlayerButton(
                    icon: paused
                        ? Icons.play_arrow_rounded
                        : Icons.pause_rounded,
                    tooltip: paused ? 'Resume' : 'Pause',
                    isPrimary: true,
                    onTap: _togglePause,
                  ),
                  AppPlayerButton(
                    icon: Icons.add_rounded,
                    tooltip: 'Add 15 seconds',
                    label: '15 sec',
                    onTap: _addFifteen,
                  ),
                  AppPlayerButton(
                    icon: Icons.skip_next_rounded,
                    tooltip: 'Skip to next stretch',
                    onTap: () => setState(_advance),
                  ),
                ],
              ),
              14.verticalSpace,
              AppProgressBar(
                value: _totalSeconds == 0 ? 0 : _elapsedSeconds / _totalSeconds,
                height: 3,
                color: colors.warm,
                trackColor: colors.playerInk.withValues(alpha: 0.12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
