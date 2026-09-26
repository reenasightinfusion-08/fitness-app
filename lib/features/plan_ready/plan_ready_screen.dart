import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:fitness_app/core/providers/providers.dart';
import 'package:fitness_app/core/theme/theme.dart';
import 'package:fitness_app/core/widgets/widgets.dart';
import 'package:fitness_app/features/get_ready/get_ready_screen.dart';
import 'package:fitness_app/features/home/models/today_plan.dart';
import 'package:fitness_app/features/onboarding_setup/models/onboarding_options.dart';
import 'package:fitness_app/features/onboarding_setup/models/onboarding_profile.dart';
import 'package:fitness_app/features/onboarding_setup/providers/onboarding_profile_provider.dart';

/// Matches the prototype's `screens.ready`: the reveal after the setup
/// wizard, before the person ever sees the tabbed home shell. Explains
/// *why* the plan looks the way it does, then either starts it or heads
/// into the app.
class PlanReadyScreen extends ConsumerWidget {
  const PlanReadyScreen({super.key});

  /// The prototype defaults every stretch's hold to 30s until a real plan
  /// generator sets one per stretch; there's no backend yet so this
  /// stands in for that, same as [TodayDemoData].
  static const int _defaultHoldSeconds = 30;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final profile = ref.watch(onboardingProfileProvider);
    final plan = TodayDemoData.todaysPlan;
    final firstName = profile.name.trim().isEmpty
        ? 'there'
        : profile.name.trim().split(' ').first;
    final reasons = _planReasons(profile);

    return Scaffold(
      backgroundColor: colors.ground,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: AppInsets.page,
                children: [
                  AppPageHeader(
                    eyebrow: 'Your plan is ready',
                    title: "$firstName, here are today's ${plan.minutes} min.",
                  ),
                  20.verticalSpace,
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Why these stretches',
                          style: AppTextStyle.titleMedium,
                        ),
                        12.verticalSpace,
                        AppReasonList(items: reasons),
                      ],
                    ),
                  ),
                  16.verticalSpace,
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${plan.stretches.length} stretches, in this order',
                          style: AppTextStyle.titleMedium,
                        ),
                        2.verticalSpace,
                        Text(
                          plan.stretches.map((s) => s.name).join(' → '),
                          style: AppTextStyle.meta.copyWith(
                            color: colors.ink2,
                          ),
                        ),
                        6.verticalSpace,
                        for (var i = 0; i < plan.stretches.length; i++)
                          AppSettingRow(
                            title: plan.stretches[i].name,
                            subtitle: '$_defaultHoldSeconds s',
                            leading: AppThumb(
                              child: StretchFigure(
                                pose: plan.stretches[i].pose,
                              ),
                            ),
                            trailing: Icon(
                              Icons.info_outline_rounded,
                              size: 18.r,
                              color: colors.ink3,
                            ),
                            showDivider: i < plan.stretches.length - 1,
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
                  label: "Start today's plan",
                  icon: Icons.play_arrow_rounded,
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => GetReadyScreen(plan: plan),
                    ),
                  ),
                ),
                AppButton(
                  label: 'Look around first',
                  variant: AppButtonVariant.text,
                  onPressed: () =>
                      ref.read(appFlowProvider.notifier).enterApp(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Mirrors the prototype's `planReasons()` — one line per profile answer
  /// that shaped the plan, ending with the two lines that always apply.
  List<String> _planReasons(OnboardingProfile p) {
    final out = <String>[];

    if (p.painAreas.isNotEmpty) {
      final areas = p.painAreas
          .map((k) => (painAreaLabels[k] ?? k).toLowerCase())
          .join(', ');
      out.add('Extra time on your $areas');
    }
    if (p.goals.isNotEmpty) {
      final labels = p.goals
          .map(
            (id) =>
                goalOptions.firstWhere((g) => g.id == id).label.toLowerCase(),
          )
          .join(' and ');
      out.add('Aimed at: $labels');
    }
    if (p.noKneel) out.add('No kneeling. Kneeling stretches are swapped out');
    if (p.noFloor) out.add('Everything is done standing or in a chair');
    for (final entry in p.injurySeverity.entries) {
      final label = (injuryAreaLabels[entry.key] ?? entry.key).toLowerCase();
      out.add(
        entry.value == InjurySeverity.mild
            ? 'Gentle options for your $label'
            : 'Skips stretches that load your $label',
      );
    }
    if (p.isPregnant) {
      out.add('Pregnancy-safe: nothing on your front, no deep twists');
    }
    if (p.hadRecentSurgery) {
      out.add('Beginner intensity while you recover from surgery');
    }

    out.add(
      p.equipmentNone || p.equipment.isEmpty
          ? 'No equipment needed'
          : 'Uses your ${p.equipment.map((id) => (equipmentLabels[id] ?? id).toLowerCase()).join(' and ')}',
    );

    final level = calcFlexibilityLevel(p.flexAnswers);
    out.add(
      '${flexibilityLevelLabels[level]} holds: $_defaultHoldSeconds seconds',
    );
    out.add(
      'Standing first, then seated, then floor, so you never jump up and down',
    );
    return out;
  }
}
