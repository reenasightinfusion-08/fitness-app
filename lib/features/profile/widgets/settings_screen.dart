import 'dart:async';

import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:fitness_app/core/theme/theme.dart';
import 'package:fitness_app/core/widgets/widgets.dart';
import 'package:fitness_app/features/profile/models/session_settings.dart';
import 'package:fitness_app/features/profile/providers/session_settings_provider.dart';
import 'package:fitness_app/services/audio_service.dart';

/// Matches the prototype's `screens.settings`: guidance and streak-day
/// preferences for a session.
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
  bool isSaving = false;

  /// What the controls show. Nothing reaches the app until Save is pressed.
  late SessionSettings draft = ref.read(sessionSettingsProvider);

  bool get isDirty => draft != ref.read(sessionSettingsProvider);

  void edit(SessionSettings next) => setState(() => draft = next);

  Future<void> save() async {
    if (isSaving) return;
    setState(() => isSaving = true);
    final synced = await ref
        .read(sessionSettingsProvider.notifier)
        .apply(draft);
    if (!mounted) return;
    setState(() => isSaving = false);
    if (synced) {
      AppSnackBar.showSuccess(context, 'Session settings saved.');
    } else {
      AppSnackBar.showError(
        context,
        "Saved on this device, but couldn't reach your account.",
      );
    }
    Navigator.of(context).pop();
  }

  Future<void> leave() async {
    if (isDirty) {
      final discard = await AppBottomSheet.confirm(
        context,
        title: 'Discard changes?',
        message: "You haven't saved your changes to Session settings.",
        confirmLabel: 'Discard',
        isDestructive: true,
      );
      if (!discard) return;
    }
    if (mounted) Navigator.of(context).pop();
  }

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
  Future<void> testSound(GuidanceMode mode, double rate) async {
    if (isSpeaking) return;
    setState(() => isSpeaking = true);
    try {
      await AudioService.instance.init();
      await AudioService.instance
          .preview(GuideMode.values.byName(mode.name), rate: rate)
          .timeout(const Duration(seconds: 8), onTimeout: () {});
    } catch (_) {
      if (mounted) {
        AppSnackBar.showError(
          context,
          "Couldn't play the sample. Check your device's sound settings.",
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
    final settings = draft;

    return Scaffold(
      backgroundColor: colors.ground,
      appBar: AppTopBar(title: 'Session settings', onBack: leave),
      body: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) leave();
        },
        child: Column(
          children: [
            Expanded(
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
                    onChanged: (mode) => edit(settings.copyWith(guidance: mode)),
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
                      onChanged: (rate) => edit(settings.copyWith(voiceRate: rate)),
                    ),
                  ),
                  if (settings.guidance == GuidanceMode.silent)
                    Text(
                      'Silent plays no voice, tones or vibration.',
                      style: AppTextStyle.meta.copyWith(color: colors.ink2),
                    )
                  else
                    AppButton(
                      label: switch (settings.guidance) {
                        GuidanceMode.voice => 'Test the voice',
                        GuidanceMode.beeps => 'Test the beeps',
                        GuidanceMode.silent => '',
                      },
                      icon: isSpeaking
                          ? Icons.pause_rounded
                          : Icons.volume_up_rounded,
                      variant: AppButtonVariant.secondary,
                      size: AppButtonSize.small,
                      isExpanded: false,
                      onPressed: isSpeaking
                          ? stopVoice
                          : () => testSound(settings.guidance, settings.voiceRate),
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
                      onChanged: (value) => edit(settings.copyWith(musicOn: value)),
                      semanticLabel: 'Background music',
                    ),
                    onTap: () => edit(settings.copyWith(musicOn: !settings.musicOn)),
                  ),
                  AppSettingRow(
                    title: 'Show calories',
                    subtitle: 'Off by default',
                    trailing: AppSwitch(
                      value: settings.showCalories,
                      onChanged: (value) => edit(settings.copyWith(showCalories: value)),
                      semanticLabel: 'Show calories',
                    ),
                    onTap: () => edit(
                      settings.copyWith(showCalories: !settings.showCalories),
                    ),
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
                      if (hour != null) edit(settings.copyWith(dayStartHour: hour));
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
            AppBottomActionBar(
              children: [
                AppButton(
                  label: 'Save',
                  isLoading: isSaving,
                  onPressed: isDirty ? save : null,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
