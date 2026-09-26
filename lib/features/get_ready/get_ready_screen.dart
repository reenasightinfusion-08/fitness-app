import 'package:flutter/material.dart';

import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:fitness_app/core/theme/theme.dart';
import 'package:fitness_app/core/widgets/widgets.dart';
import 'package:fitness_app/features/home/models/today_plan.dart';
import 'package:fitness_app/features/session_player/session_player_screen.dart';

/// How the session narrates itself — the prototype's `settings.guide`.
enum GuideMode { voice, beeps, silent }

/// Matches the prototype's `screens.getready`: the settings screen shown
/// right before a session starts — guidance style, background music, and
/// how long to hold each stretch this time. "Begin" hands off to the
/// session player.
class GetReadyScreen extends StatefulWidget {
  const GetReadyScreen({super.key, required this.plan});

  final RoutineSummary plan;

  @override
  State<GetReadyScreen> createState() => GetReadyScreenState();
}

class GetReadyScreenState extends State<GetReadyScreen> {
  static const int _minHoldSeconds = 15;
  static const int _maxHoldSeconds = 120;
  static const int _holdStepSeconds = 5;

  GuideMode guideMode = GuideMode.voice;
  bool musicOn = true;
  late int holdSeconds = widget.plan.stretches.first.holdSeconds;

  String get _guideDescription => switch (guideMode) {
    GuideMode.voice =>
      'Names each stretch, cues side switches, counts down the last 10 seconds.',
    GuideMode.beeps =>
      'A chime to start, a double chime to switch sides, ticks for 3-2-1.',
    GuideMode.silent => 'Vibration only, where your phone supports it.',
  };

  void _adjustHold(int delta) => setState(
    () => holdSeconds = (holdSeconds + delta).clamp(
      _minHoldSeconds,
      _maxHoldSeconds,
    ),
  );

  void _begin() => Navigator.of(context).pushReplacement(
    MaterialPageRoute(
      builder: (_) => SessionPlayerScreen(
        plan: widget.plan,
        holdSecondsOverride: holdSeconds,
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final firstStretch = widget.plan.stretches.first;

    return Scaffold(
      backgroundColor: colors.ground,
      appBar: AppTopBar(
        title: 'Get ready',
        onBack: () => Navigator.of(context).pop(),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: AppInsets.page,
                children: [
                  AspectRatio(
                    aspectRatio: 16 / 9,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: colors.surface,
                        border: Border.all(color: colors.line),
                        borderRadius: AppBorderRadius.hero,
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(28.r),
                        child: AnimatedStretchFigure(pose: firstStretch.pose),
                      ),
                    ),
                  ),
                  16.verticalSpace,
                  Text(
                    '${widget.plan.name} · ${widget.plan.minutes} min',
                    style: AppTextStyle.eyebrow.copyWith(color: colors.ink3),
                  ),
                  4.verticalSpace,
                  Text(
                    'First up: ${firstStretch.name}',
                    style: AppTextStyle.headline,
                  ),
                  4.verticalSpace,
                  Text(
                    '${widget.plan.stretches.length} stretches',
                    style: AppTextStyle.bodyMedium.copyWith(
                      color: colors.ink2,
                    ),
                  ),
                  20.verticalSpace,
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const AppFieldLabel(text: 'Guidance'),
                        8.verticalSpace,
                        AppSegmentedControl<GuideMode>(
                          segments: const [
                            AppSegmentModel(
                              value: GuideMode.voice,
                              label: 'Voice',
                            ),
                            AppSegmentModel(
                              value: GuideMode.beeps,
                              label: 'Beeps only',
                            ),
                            AppSegmentModel(
                              value: GuideMode.silent,
                              label: 'Silent',
                            ),
                          ],
                          value: guideMode,
                          onChanged: (value) =>
                              setState(() => guideMode = value),
                        ),
                        8.verticalSpace,
                        Text(
                          _guideDescription,
                          style: AppTextStyle.meta.copyWith(
                            color: colors.ink2,
                          ),
                        ),
                        4.verticalSpace,
                        AppSettingRow(
                          title: 'Calm background music',
                          subtitle: 'Gets quieter whenever the voice speaks',
                          trailing: AppSwitch(
                            value: musicOn,
                            onChanged: (value) =>
                                setState(() => musicOn = value),
                            semanticLabel: 'Background music',
                          ),
                        ),
                        AppSettingRow(
                          title: 'Hold time',
                          subtitle: 'For this session',
                          showDivider: false,
                          trailing: AppStepper(
                            valueLabel: '${holdSeconds}s',
                            onDecrement: holdSeconds <= _minHoldSeconds
                                ? null
                                : () => _adjustHold(-_holdStepSeconds),
                            onIncrement: holdSeconds >= _maxHoldSeconds
                                ? null
                                : () => _adjustHold(_holdStepSeconds),
                          ),
                        ),
                      ],
                    ),
                  ),
                  12.verticalSpace,
                  Text(
                    "Tip: prop your phone where you can hear it. "
                    "You won't need to look at it.",
                    style: AppTextStyle.meta.copyWith(color: colors.ink2),
                  ),
                ],
              ),
            ),
            AppBottomActionBar(
              children: [
                AppButton(
                  label: 'Begin',
                  icon: Icons.play_arrow_rounded,
                  onPressed: _begin,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
