import 'dart:async';

import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:fitness_app/core/theme/theme.dart';
import 'package:fitness_app/core/widgets/widgets.dart';
import 'package:fitness_app/features/profile/models/session_settings.dart';
import 'package:fitness_app/features/profile/providers/session_settings_provider.dart';
import 'package:fitness_app/services/audio_service.dart';

/// Matches the prototype's `screens.settings`: guidance, timing and
/// streak-day preferences for a session.
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => SettingsScreenState();
}

class SettingsScreenState extends ConsumerState<SettingsScreen> {
  /// True for as long as the sample line is actually being spoken — while
  /// true the button reads "Stop" so tapping it again cuts the voice off,
  /// instead of only ever offering to start it again.
  bool isSpeaking = false;

  /// Speaks a sample line through [AudioService], at the currently-selected
  /// rate — regardless of the Guidance mode, since testing the voice only
  /// makes sense when you can hear it. A second tap while it's talking
  /// calls [stopSpeaking] instead (wired from the button below).
  ///
  /// [FlutterTts]'s "speech finished" event doesn't fire reliably on
  /// every platform/engine, so awaiting it can hang forever — which once
  /// left this button stuck. A timeout caps how long we wait: the voice
  /// still plays either way, but the button always recovers even if the
  /// platform never reports completion.
  Future<void> testVoice(double rate) async {
    if (isSpeaking) return;
    setState(() => isSpeaking = true);
    try {
      await AudioService.instance.init();
      await AudioService.instance
          .speak("Here's how your stretch cues will sound.", rate: rate)
          .timeout(const Duration(seconds: 6), onTimeout: () {});
    } catch (_) {
      if (mounted) {
        AppSnackBar.showError(
          context,
          "Couldn't play the voice. Check your device's text-to-speech.",
        );
      }
    } finally {
      if (mounted) setState(() => isSpeaking = false);
    }
  }

  Future<void> stopVoice() async {
    await AudioService.instance.stopSpeaking();
    if (mounted) setState(() => isSpeaking = false);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final settings = ref.watch(sessionSettingsProvider);
    final notifier = ref.read(sessionSettingsProvider.notifier);

    return Scaffold(
      backgroundColor: colors.ground,
      appBar: AppTopBar(
        title: 'Session settings',
        onBack: () => Navigator.of(context).pop(),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: AppInsets.page,
          children: [
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Guidance', style: AppTextStyle.titleMedium),
                  12.verticalSpace,
                  AppSegmentedControl<GuidanceMode>(
                    segments: [
                      for (final mode in GuidanceMode.values)
                        AppSegmentModel(
                          value: mode,
                          label: guidanceModeLabels[mode]!,
                        ),
                    ],
                    value: settings.guidance,
                    onChanged: notifier.setGuidance,
                  ),
                  16.verticalSpace,
                  Text(
                    'Voice speed · ${settings.voiceRate.toStringAsFixed(1)}×',
                    style: AppTextStyle.label.copyWith(color: colors.ink2),
                  ),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: colors.accent,
                      inactiveTrackColor: colors.surface2,
                      thumbColor: colors.accent,
                      overlayColor: colors.accentSoft,
                    ),
                    child: Slider(
                      value: settings.voiceRate,
                      min: 0.7,
                      max: 1.3,
                      divisions: 6,
                      onChanged: notifier.setVoiceRate,
                    ),
                  ),
                  AppButton(
                    label: 'Test the voice',
                    icon: isSpeaking
                        ? Icons.pause_rounded
                        : Icons.volume_up_rounded,
                    variant: AppButtonVariant.secondary,
                    size: AppButtonSize.small,
                    isExpanded: false,
                    onPressed: isSpeaking
                        ? stopVoice
                        : () => testVoice(settings.voiceRate),
                  ),
                ],
              ),
            ),
            16.verticalSpace,
            AppCard(
              variant: AppCardVariant.list,
              child: Column(
                children: [
                  AppSettingRow(
                    title: 'Calm background music',
                    subtitle:
                        'Lowers automatically when the voice speaks. Your '
                        'own music also works; the app never stops it.',
                    trailing: AppSwitch(
                      value: settings.musicOn,
                      onChanged: notifier.setMusicOn,
                      semanticLabel: 'Background music',
                    ),
                    onTap: () => notifier.setMusicOn(!settings.musicOn),
                  ),
                  AppSettingRow(
                    title: 'Show calories',
                    subtitle: 'Off by default',
                    trailing: AppSwitch(
                      value: settings.showCalories,
                      onChanged: notifier.setShowCalories,
                      semanticLabel: 'Show calories',
                    ),
                    onTap: () =>
                        notifier.setShowCalories(!settings.showCalories),
                    showDivider: false,
                  ),
                ],
              ),
            ),
            16.verticalSpace,
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Timing', style: AppTextStyle.titleMedium),
                  14.verticalSpace,
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Extra hold time', style: AppTextStyle.titleSmall),
                            Text(
                              'Added to every stretch',
                              style: AppTextStyle.meta.copyWith(
                                color: colors.ink2,
                              ),
                            ),
                          ],
                        ),
                      ),
                      AppStepper(
                        valueLabel:
                            '${settings.extraHoldSeconds >= 0 ? '+' : ''}'
                            '${settings.extraHoldSeconds}s',
                        onDecrement: settings.extraHoldSeconds <=
                                minExtraHoldSeconds
                            ? null
                            : () => notifier.stepExtraHold(-holdStepSeconds),
                        onIncrement: settings.extraHoldSeconds >=
                                maxExtraHoldSeconds
                            ? null
                            : () => notifier.stepExtraHold(holdStepSeconds),
                      ),
                    ],
                  ),
                  16.verticalSpace,
                  Text(
                    'Extra time to change position',
                    style: AppTextStyle.label.copyWith(color: colors.ink2),
                  ),
                  8.verticalSpace,
                  AppSegmentedControl<int>(
                    segments: [
                      for (final v in transitionExtraOptions)
                        AppSegmentModel(
                          value: v,
                          label: v == 0 ? 'Standard' : '+${v}s',
                        ),
                    ],
                    value: settings.extraTransitionSeconds,
                    onChanged: notifier.setExtraTransition,
                  ),
                  8.verticalSpace,
                  Text(
                    'Standard gives 6s for the same position and 15s from '
                    'standing to the floor.',
                    style: AppTextStyle.meta.copyWith(color: colors.ink2),
                  ),
                ],
              ),
            ),
            16.verticalSpace,
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Streaks', style: AppTextStyle.titleMedium),
                  12.verticalSpace,
                  AppDropDown<int>(
                    label: 'My day starts at',
                    value: settings.dayStartHour,
                    items: [
                      for (final hour in dayStartHourOptions)
                        AppDropDownItemModel(
                          value: hour,
                          label: dayStartHourLabel(hour),
                        ),
                    ],
                    onChanged: (hour) {
                      if (hour != null) notifier.setDayStartHour(hour);
                    },
                  ),
                  8.verticalSpace,
                  Text(
                    'Stretching at 1am after a late night still counts for '
                    'the day before.',
                    style: AppTextStyle.meta.copyWith(color: colors.ink2),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
