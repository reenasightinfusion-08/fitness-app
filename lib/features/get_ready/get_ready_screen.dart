import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:fitness_app/core/providers/providers.dart';
import 'package:fitness_app/core/theme/theme.dart';
import 'package:fitness_app/features/profile/providers/session_settings_provider.dart';
import 'package:fitness_app/core/widgets/widgets.dart';
import 'package:fitness_app/features/home/models/today_plan.dart';
import 'package:fitness_app/features/session_player/session_player_screen.dart';
import 'package:fitness_app/services/audio_service.dart' show GuideMode;

/// Matches the prototype's `screens.getready`: the settings screen shown
/// right before a session starts — guidance style, background music, and
/// how long to hold each stretch this time. "Begin" hands off to the
/// session player.
class GetReadyScreen extends ConsumerStatefulWidget {
  const GetReadyScreen({
    super.key,
    required this.plan,
    this.source = 'user',
    this.routineType = 'system',
  });

  final RoutineSummary plan;

  /// 'plan' when started from today's plan, so finishing it counts as the
  /// day's plan being done; 'user' for a routine the person picked themselves.
  final String source;

  /// 'system' for the app's routines, 'custom' for ones the user built.
  final String routineType;

  @override
  ConsumerState<GetReadyScreen> createState() => GetReadyScreenState();
}

class GetReadyScreenState extends ConsumerState<GetReadyScreen> {
  static const int _minHoldSeconds = 15;
  static const int _maxHoldSeconds = 120;
  static const int _holdStepSeconds = 5;

  bool isStarting = false;
  late GuideMode guideMode = GuideMode.values.byName(
    ref.read(sessionSettingsProvider).guidance.name,
  );
  late bool musicOn = ref.read(sessionSettingsProvider).musicOn;
  late int holdSeconds = widget.plan.stretches.first.holdSeconds;

  String get _guideDescription => switch (guideMode) {
    GuideMode.voice =>
      'Names each stretch, cues side switches, counts down the last 10 seconds.',
    GuideMode.beeps =>
      'A chime to start, a double chime to switch sides, ticks for 3-2-1.',
    GuideMode.silent => 'No voice, tones or vibration.',
  };

  void _adjustHold(int delta) => setState(
    () => holdSeconds = (holdSeconds + delta).clamp(
      _minHoldSeconds,
      _maxHoldSeconds,
    ),
  );

  /// Records the routine as begun on the server first, so the player can save
  /// progress from its very first stretch. If that can't be done the session
  /// still plays, it just can't be resumed later.
  Future<void> begin() async {
    if (isStarting) return;
    setState(() => isStarting = true);
    final container = ProviderScope.containerOf(context);
    final navigator = Navigator.of(context);
    final onProgress = await beginTrackedRoutine(
      container,
      widget.plan,
      routineType: widget.routineType,
      source: widget.source,
    );
    if (!mounted) return;
    navigator.pushReplacement(
      MaterialPageRoute(
        builder: (_) => SessionPlayerScreen(
          plan: widget.plan,
          holdSecondsOverride: holdSeconds,
          guideMode: guideMode,
          musicOn: musicOn,
          voiceRate: ref.read(sessionSettingsProvider).voiceRate,
          onProgress: onProgress,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final firstStretch =
        widget.plan.stretches.isNotEmpty ? widget.plan.stretches.first : null;
    final thumbUrl = firstStretch?.model?.thumbnailUrl;
    final hasThumb = thumbUrl != null && thumbUrl.trim().isNotEmpty;

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
                      child: ClipRRect(
                        borderRadius: AppBorderRadius.hero,
                        child: hasThumb
                            ? Image.network(
                                thumbUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    Padding(
                                  padding: EdgeInsets.all(28.r),
                                  child: AnimatedStretchFigure(
                                    pose: firstStretch?.pose ??
                                        StretchPoses.neutral,
                                  ),
                                ),
                              )
                            : Padding(
                                padding: EdgeInsets.all(28.r),
                                child: AnimatedStretchFigure(
                                  pose: firstStretch?.pose ??
                                      StretchPoses.neutral,
                                ),
                              ),
                      ),
                    ),
                  ),
                  16.verticalSpace,
                  Text(
                    '${widget.plan.name} · ${widget.plan.durationText}',
                    style: AppTextStyle.eyebrow.copyWith(color: colors.ink3),
                  ),
                  4.verticalSpace,
                  Text(
                    'First up: ${firstStretch?.name ?? ''}',
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
                          showDivider: false,
                          trailing: AppSwitch(
                            value: musicOn,
                            onChanged: (value) =>
                                setState(() => musicOn = value),
                            semanticLabel: 'Background music',
                          ),
                        ),
                        // AppSettingRow(
                        //   title: 'Hold time',
                        //   subtitle: 'For this session',
                        //   showDivider: false,
                        //   trailing: AppStepper(
                        //     valueLabel: '${holdSeconds}s',
                        //     onDecrement: holdSeconds <= _minHoldSeconds
                        //         ? null
                        //         : () => _adjustHold(-_holdStepSeconds),
                        //     onIncrement: holdSeconds >= _maxHoldSeconds
                        //         ? null
                        //         : () => _adjustHold(_holdStepSeconds),
                        //   ),
                        // ),
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
                  isLoading: isStarting,
                  onPressed: begin,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
