import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:fitness_app/core/providers/providers.dart';
import 'package:fitness_app/core/theme/theme.dart';
import 'package:fitness_app/core/widgets/widgets.dart';
import 'package:fitness_app/features/get_ready/get_ready_screen.dart';
import 'package:fitness_app/features/home/models/plan_overview_model.dart';
import 'package:fitness_app/features/home/widgets/stretch_thumbnail.dart';
import 'package:fitness_app/features/home/widgets/todays_plan_error_card.dart';
import 'package:fitness_app/features/onboarding_setup/models/onboarding_options.dart';
import 'package:fitness_app/features/onboarding_setup/models/onboarding_profile.dart';
import 'package:fitness_app/features/onboarding_setup/providers/onboarding_profile_provider.dart';

/// Matches the prototype's `screens.ready`: the reveal after the setup
/// wizard, before the person ever sees the tabbed home shell. Tells them how
/// many days of plan they got and what each day holds, explains *why* it
/// fits, then either starts today's routine or heads into the app.
class PlanReadyScreen extends ConsumerWidget {
  const PlanReadyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final overviewAsync = ref.watch(planOverviewProvider);

    return Scaffold(
      backgroundColor: context.colors.ground,
      body: SafeArea(
        child: overviewAsync.when(
          data: (overview) => PlanReadyContent(overview: overview),
          loading: () => const Center(child: AppLoader()),
          error: (error, stack) => Padding(
            padding: AppInsets.page,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TodaysPlanErrorCard(
                  error: error,
                  onRetry: () => ref.invalidate(planOverviewProvider),
                ),
                16.verticalSpace,
                AppButton(
                  label: 'Look around first',
                  variant: AppButtonVariant.text,
                  onPressed: () => ref.read(appFlowProvider.notifier).enterApp(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The loaded half of [PlanReadyScreen]: the plan's length, why it fits, and a
/// card per day with every stretch's photo.
class PlanReadyContent extends ConsumerWidget {
  const PlanReadyContent({super.key, required this.overview});

  final PlanOverviewModel overview;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(onboardingProfileProvider);
    final firstName = profile.name.trim().isEmpty
        ? 'there'
        : profile.name.trim().split(' ').first;
    final days = overview.planDays;
    final reasons = planReasons(profile);

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: AppInsets.page,
            children: [
              AppPageHeader(
                eyebrow: 'Your plan is ready',
                title: days == 1
                    ? '$firstName, you got a 1-day plan.'
                    : '$firstName, you got a $days-day plan.',
              ),
              8.verticalSpace,
              Text(
                overview.summary.isNotEmpty
                    ? overview.summary
                    : days == 1
                    ? 'One routine, repeated each day.'
                    : 'A different routine each day. After day $days it starts again from day 1.',
                style: AppTextStyle.bodySmall.copyWith(
                  color: context.colors.ink2,
                ),
              ),
              20.verticalSpace,
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Why this plan', style: AppTextStyle.titleMedium),
                    12.verticalSpace,
                    AppReasonList(items: reasons),
                  ],
                ),
              ),
              for (final day in overview.days) ...[
                16.verticalSpace,
                PlanDayCard(day: day),
              ],
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
                  builder: (_) => GetReadyScreen(
                    plan: overview.today.routine,
                    source: 'plan',
                  ),
                ),
              ),
            ),
            AppButton(
              label: 'Look around first',
              variant: AppButtonVariant.text,
              onPressed: () => ref.read(appFlowProvider.notifier).enterApp(),
            ),
          ],
        ),
      ],
    );
  }

  /// Mirrors the prototype's `planReasons()` — one line per profile answer
  /// that shaped the plan, ending with the lines that always apply. Each line
  /// matches a rule the server applies when it picks the routine
  /// (`backend/utils/dailyPlan.js`), so the list never promises more than the
  /// plan does.
  List<String> planReasons(OnboardingProfile p) {
    final out = <String>[];

    if (p.painAreas.isNotEmpty) {
      final areas = p.painAreas
          .map((k) => (painAreaLabels[k] ?? k).toLowerCase())
          .join(', ');
      out.add('Focused on your $areas');
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
    if (p.noKneel) out.add('No kneeling in any of today\'s stretches');
    if (p.noFloor) out.add('Everything is done standing or in a chair');
    for (final entry in p.injurySeverity.entries) {
      if (entry.value == InjurySeverity.mild) continue;
      final label = (injuryAreaLabels[entry.key] ?? entry.key).toLowerCase();
      out.add('Avoids routines that load your $label');
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
      'Matched to your ${flexibilityLevelLabels[level].toLowerCase()} flexibility level',
    );
    out.add('Fits your ${p.minutesPerDay} minutes a day');
    return out;
  }
}

/// One day of the plan: its routine, how long it takes and every stretch's photo.
class PlanDayCard extends StatelessWidget {
  const PlanDayCard({super.key, required this.day});

  final PlanDayModel day;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final routine = day.routine;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Day ${day.day} · ${routine.minutes} min · ${routine.stretches.length} stretches',
                  style: AppTextStyle.eyebrow.copyWith(color: colors.ink3),
                ),
              ),
              if (day.isToday)
                const AppTag(label: 'Today', tone: AppTone.accent),
            ],
          ),
          2.verticalSpace,
          Text(routine.name, style: AppTextStyle.display(22)),
          if (day.reason.isNotEmpty) ...[
            4.verticalSpace,
            Text(
              day.reason,
              style: AppTextStyle.bodySmall.copyWith(color: colors.ink2),
            ),
          ] else if (routine.blurb != null &&
              routine.blurb!.trim().isNotEmpty) ...[
            4.verticalSpace,
            Text(
              routine.blurb!,
              style: AppTextStyle.bodySmall.copyWith(color: colors.ink2),
            ),
          ],
          12.verticalSpace,
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final stretch in routine.stretches) ...[
                  StretchThumbnail(stretch: stretch),
                  6.horizontalSpace,
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
