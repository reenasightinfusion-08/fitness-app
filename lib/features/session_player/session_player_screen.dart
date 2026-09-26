import 'dart:async';

import 'package:flutter/material.dart';

import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:fitness_app/core/theme/theme.dart';
import 'package:fitness_app/core/widgets/widgets.dart';
import 'package:fitness_app/features/explore/models/explore_data.dart';
import 'package:fitness_app/features/home/models/today_plan.dart';
import 'package:fitness_app/features/session_complete/session_complete_screen.dart';
import 'package:fitness_app/features/stretch_detail/models/stretch_guide.dart';
import 'package:fitness_app/features/stretch_detail/stretch_detail_sheet.dart';

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

List<_SessionStep> _buildSteps(RoutineSummary plan, int? holdOverride) {
  final steps = <_SessionStep>[];
  for (var i = 0; i < plan.stretches.length; i++) {
    final stretch = plan.stretches[i];
    final hold = holdOverride ?? stretch.holdSeconds;
    steps.add(_SessionStep(kind: _StepKind.getReady, stretchIndex: i, durationSeconds: 8));
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
        _SessionStep(kind: _StepKind.switchSides, stretchIndex: i, durationSeconds: 5),
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
        _SessionStep(kind: _StepKind.hold, stretchIndex: i, durationSeconds: hold),
      );
    }
  }
  return steps;
}

String _phaseLabel(_SessionStep step, bool isFirstStretch) => switch (step.kind) {
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
  const SessionPlayerScreen({super.key, required this.plan, this.holdSecondsOverride});

  final RoutineSummary plan;

  /// Overrides every stretch's hold time for this session — the "Hold
  /// time" stepper on the Get Ready screen.
  final int? holdSecondsOverride;

  @override
  State<SessionPlayerScreen> createState() => SessionPlayerScreenState();
}

class SessionPlayerScreenState extends State<SessionPlayerScreen> {
  late final List<_SessionStep> steps = _buildSteps(
    widget.plan,
    widget.holdSecondsOverride,
  );
  late int remaining = steps.first.durationSeconds;
  int stepIndex = 0;
  bool paused = false;
  Timer? _ticker;

  /// A per-session working copy of the plan's stretches, so "Swap" can
  /// replace one stretch for this session without mutating [widget.plan]
  /// itself — mirrors the prototype's `S.items[st.i]={...}`.
  late final List<StretchPreview> _stretches = List.of(widget.plan.stretches);

  _SessionStep get currentStep => steps[stepIndex];
  StretchPreview get currentStretch => _stretches[currentStep.stretchIndex];

  int get _totalSeconds =>
      steps.fold(0, (sum, step) => sum + step.durationSeconds);
  int get _elapsedSeconds =>
      steps
          .take(stepIndex)
          .fold(0, (sum, step) => sum + step.durationSeconds) +
      (currentStep.durationSeconds - remaining);

  @override
  void initState() {
    super.initState();
    _startTicker();
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (paused) return;
      setState(() {
        if (remaining > 1) {
          remaining -= 1;
        } else {
          _advance();
        }
      });
    });
  }

  void _advance() {
    if (stepIndex >= steps.length - 1) {
      _finish();
      return;
    }
    stepIndex += 1;
    remaining = steps[stepIndex].durationSeconds;
  }

  void _goBack() {
    setState(() {
      stepIndex = stepIndex > 0 ? stepIndex - 1 : 0;
      remaining = steps[stepIndex].durationSeconds;
    });
  }

  void _finish() {
    _ticker?.cancel();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => SessionCompleteScreen(plan: widget.plan),
      ),
    );
  }

  void _exit() => Navigator.of(context).popUntil((route) => route.isFirst);

  void _togglePause() => setState(() => paused = !paused);

  void _addFifteen() => setState(() => remaining += 15);

  /// Replaces the current stretch with the best-matching alternative that
  /// isn't already in this session — mirrors the prototype's `plSwap()` /
  /// `bestAlt()`: most shared body areas wins, ties broken by matching
  /// position (standing/seated/floor).
  void _swap() {
    final current = currentStretch;
    final currentAreas = ExploreDemoData.stretches
        .firstWhere(
          (s) => s.pose == current.pose,
          orElse: () =>
              ExploreStretch(name: current.name, pose: current.pose, areas: const []),
        )
        .areas;
    final usedPoses = _stretches.map((s) => s.pose).toSet();

    ExploreStretch? best;
    var bestScore = 0;
    for (final candidate in ExploreDemoData.stretches) {
      if (usedPoses.contains(candidate.pose)) continue;
      final overlap = candidate.areas.where(currentAreas.contains).length;
      if (overlap == 0) continue;
      final samePosition =
          StretchLibrary.guideFor(candidate.pose)?.position == current.position;
      final score = overlap * 3 + (samePosition ? 1 : 0);
      if (score > bestScore) {
        bestScore = score;
        best = candidate;
      }
    }

    if (best == null) {
      AppSnackBar.show(
        context,
        'No similar stretch available for this one. Try skip instead.',
      );
      return;
    }

    final guide = StretchLibrary.guideFor(best.pose);
    setState(() {
      _stretches[currentStep.stretchIndex] = StretchPreview(
        name: best!.name,
        pose: best.pose,
        holdSeconds: current.holdSeconds,
        position: guide?.position ?? current.position,
        isEachSide: guide?.isEachSide ?? current.isEachSide,
        feelCue: guide?.feel,
      );
      remaining = currentStep.durationSeconds;
    });
    AppSnackBar.show(context, 'Swapped to ${best.name}.');
  }

  /// Pauses the timer (like tapping pause) while the stretch-info sheet is
  /// open, then restores whatever the pause state was before — mirrors the
  /// prototype's `stretchInfo()`.
  void _showStretchInfo() {
    final wasPaused = paused;
    if (!wasPaused) setState(() => paused = true);
    StretchDetailSheet.open(
      context,
      name: currentStretch.name,
      pose: currentStretch.pose,
      note: 'Timer paused while you read.',
    ).then((_) {
      if (!mounted || wasPaused) return;
      setState(() => paused = false);
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final step = currentStep;
    final stretch = currentStretch;
    final isFirstStretch = step.stretchIndex == 0;
    final nextStretch = step.stretchIndex + 1 < _stretches.length
        ? _stretches[step.stretchIndex + 1]
        : null;

    final cue = switch (step.kind) {
      _StepKind.getReady => stretch.setupCue,
      _StepKind.switchSides => 'Slowly come out, then set up on the other side.',
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
                    SizedBox(
                      height: 220.h,
                      width: 220.w,
                      child: AnimatedStretchFigure(
                        pose: stretch.pose,
                        nearColor: colors.playerInk,
                        farColor: colors.playerDim,
                        groundColor: colors.playerInk.withValues(alpha: 0.14),
                      ),
                    ),
                    Text(
                      _formatSeconds(remaining),
                      style: AppTextStyle.timer.copyWith(
                        color: colors.playerInk,
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
                          : CustomPaint(
                              painter: StretchFigurePainter(
                                pose: nextStretch.pose,
                                nearColor: colors.playerInk,
                                farColor: colors.playerDim,
                                groundColor: Colors.transparent,
                                showGround: false,
                              ),
                            ),
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
                    tooltip: 'Swap for a similar stretch',
                    label: 'Swap',
                    onTap: _swap,
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
                    label: '+15 sec',
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
