import 'dart:async';

import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:fitness_app/core/providers/providers.dart';
import 'package:fitness_app/core/theme/theme.dart';
import 'package:fitness_app/core/widgets/widgets.dart';
import 'package:fitness_app/features/home/models/today_plan.dart';
import 'package:fitness_app/services/auth_service.dart';
import 'package:fitness_app/features/progress/providers/progress_stats_provider.dart';

enum SessionFeel { easy, right, hard }

extension SessionFeelLabel on SessionFeel {
  String get label => switch (this) {
    SessionFeel.easy => 'Too easy',
    SessionFeel.right => 'Just right',
    SessionFeel.hard => 'Too hard',
  };

  /// Matches the prototype's per-answer tuning note.
  String get tuningNote => switch (this) {
    SessionFeel.easy => 'Next time: holds 5 seconds longer.',
    SessionFeel.right => "We'll keep things as they are.",
    SessionFeel.hard => 'Next time: holds 5 seconds shorter.',
  };
}

/// Matches the prototype's `screens.complete`: the streak + "Nicely done."
/// hero, a how-did-that-feel check-in and a hurt-anything log, reached
/// after finishing a session in [SessionPlayerScreen].
class SessionCompleteScreen extends ConsumerStatefulWidget {
  const SessionCompleteScreen({super.key, required this.plan});

  final RoutineSummary plan;

  @override
  ConsumerState<SessionCompleteScreen> createState() =>
      SessionCompleteScreenState();
}

class SessionCompleteScreenState
    extends ConsumerState<SessionCompleteScreen> {
  SessionFeel? feel;
  final Set<String> hurtNames = {};

  /// The routine's stretches by name, so a tapped chip can find the saved
  /// stretch behind it. Demo routines have no saved stretches (no `model`).
  Map<String, String> get _stretchIds => {
    for (final s in widget.plan.stretches)
      if (s.model != null) s.name: s.model!.id,
  };

  @override
  void initState() {
    super.initState();
    unawaited(_showAlreadyMarked());
  }

  /// Pre-selects stretches the user marked as hurt before, so tapping one
  /// again undoes it.
  Future<void> _showAlreadyMarked() async {
    final List<HurtStretch> marked;
    try {
      marked = await ref.read(hurtStretchesProvider.future);
    } catch (_) {
      return;
    }
    if (!mounted) return;
    final ids = _stretchIds;
    setState(() {
      for (final h in marked) {
        for (final entry in ids.entries) {
          if (entry.value == h.id) hurtNames.add(entry.key);
        }
      }
    });
  }

  /// Flips a chip and saves it right away, so it counts even if the user
  /// leaves without pressing Done.
  Future<void> _toggleHurt(String name) async {
    final nowHurt = !hurtNames.contains(name);
    setState(() => nowHurt ? hurtNames.add(name) : hurtNames.remove(name));
    final id = _stretchIds[name];
    if (id == null) return;
    try {
      await ref.read(hurtStretchesProvider.notifier).setHurt(id, name, nowHurt);
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() => nowHurt ? hurtNames.remove(name) : hurtNames.add(name));
      AppSnackBar.show(context, e.message);
    }
  }

  void _notBuiltYet() =>
      AppSnackBar.show(context, "That screen isn't built yet.");

  /// A session can be launched either from the tabbed Home shell or from
  /// [PlanReadyScreen] (right after onboarding), which never advances
  /// [AppFlowController] past `planReady` — it just pushes on top of
  /// itself. `popUntil(isFirst)` alone would then land back on
  /// [PlanReadyScreen]'s "Start today's plan" instead of Home. Explicitly
  /// entering the app first guarantees "Done" always reaches the real
  /// Home shell; it's a no-op when we're already there, so the ordinary
  /// Home-started flow behaves exactly as before.
  void _finish() {
    ref.read(appFlowProvider.notifier).enterApp();
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final plan = widget.plan;
    final stretchNames = {for (final s in plan.stretches) s.name}.toList();

    return Scaffold(
      backgroundColor: colors.ground,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: AppInsets.page,
                children: [
                  AppStreakBadge(
                    days: ref.watch(progressStatsProvider).streakDays,
                    isLarge: true,
                  ),
                  14.verticalSpace,
                  Text('Nicely done.', style: AppTextStyle.headlineLarge),
                  6.verticalSpace,
                  Text(
                    '${plan.name} · ${plan.minutes} min · '
                    '${plan.stretches.length} stretches',
                    style: AppTextStyle.bodyMedium.copyWith(
                      color: colors.ink2,
                    ),
                  ),
                  24.verticalSpace,
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'How did that feel?',
                          style: AppTextStyle.titleMedium,
                        ),
                        12.verticalSpace,
                        AppSegmentedControl<SessionFeel>(
                          segments: [
                            for (final value in SessionFeel.values)
                              AppSegmentModel(value: value, label: value.label),
                          ],
                          value: feel,
                          onChanged: (value) => setState(() => feel = value),
                        ),
                        10.verticalSpace,
                        Text(
                          feel?.tuningNote ??
                              "Your answer tunes tomorrow's plan.",
                          style: AppTextStyle.meta.copyWith(
                            color: colors.ink2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  16.verticalSpace,
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Did anything hurt?',
                          style: AppTextStyle.titleMedium,
                        ),
                        4.verticalSpace,
                        Text(
                          "Tap it and we'll leave it out of your plans. "
                          'Undo anytime in Edit profile.',
                          style: AppTextStyle.bodySmall.copyWith(
                            color: colors.ink2,
                          ),
                        ),
                        12.verticalSpace,
                        Wrap(
                          spacing: 8.w,
                          runSpacing: 8.h,
                          children: [
                            for (final name in stretchNames)
                              AppChip(
                                label: name,
                                isCompact: true,
                                isSelected: hurtNames.contains(name),
                                onTap: () => _toggleHurt(name),
                              ),
                          ],
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
                  label: 'Done',
                  onPressed: _finish,
                ),
                AppButton(
                  label: 'Save as my routine',
                  variant: AppButtonVariant.text,
                  onPressed: _notBuiltYet,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
