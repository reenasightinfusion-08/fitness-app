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
import 'package:google_fonts/google_fonts.dart';

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
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520.0),
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
                      onPressed: () =>
                          ref.read(appFlowProvider.notifier).enterApp(),
                    ),
                  ],
                ),
              ),
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

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 600) {
          final isLandscape = constraints.maxWidth >= constraints.maxHeight;
          if (isLandscape || constraints.maxWidth >= 840) {
            return _buildTabletLandscape(
              context: context,
              ref: ref,
              firstName: firstName,
              days: days,
              reasons: reasons,
              constraints: constraints,
            );
          } else {
            return _buildTabletPortrait(
              context: context,
              ref: ref,
              firstName: firstName,
              days: days,
              reasons: reasons,
              constraints: constraints,
            );
          }
        }

        return _buildMobile(
          context: context,
          ref: ref,
          firstName: firstName,
          days: days,
          reasons: reasons,
        );
      },
    );
  }

  /// Mobile layout preserved exactly.
  Widget _buildMobile({
    required BuildContext context,
    required WidgetRef ref,
    required String firstName,
    required int days,
    required List<String> reasons,
  }) {
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

  /// Tablet landscape split layout: Left hero image card & right plan cards.
  Widget _buildTabletLandscape({
    required BuildContext context,
    required WidgetRef ref,
    required String firstName,
    required int days,
    required List<String> reasons,
    required BoxConstraints constraints,
  }) {
    final colors = context.colors;
    final w = constraints.maxWidth;

    final colW = w / 2;
    final formWidth = (colW * 0.85).clamp(420.0, 520.0);

    return Row(
      children: [
        // Left hero card
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24.0),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    'assets/images/onboarding_hero.jpg',
                    fit: BoxFit.cover,
                    alignment: Alignment.center,
                  ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.0),
                          Colors.black.withValues(alpha: 0.2),
                          Colors.black.withValues(alpha: 0.8),
                        ],
                        stops: const [0.4, 0.65, 1.0],
                      ),
                    ),
                  ),
                    Positioned(
                      left: 20.0,
                      right: 20.0,
                      bottom: 20.0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20.0,
                          vertical: 16.0,
                        ),
                        decoration: BoxDecoration(
                          color: colors.surface.withValues(alpha: 0.94),
                          borderRadius: BorderRadius.circular(18.0),
                          border: Border.all(
                            color: colors.line.withValues(alpha: 0.5),
                            width: 1.0,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.16),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12.0,
                                vertical: 5.0,
                              ),
                              decoration: BoxDecoration(
                                color: colors.accent.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(10.0),
                              ),
                              child: Text(
                                'PLAN READY',
                                style: GoogleFonts.figtree(
                                  fontSize: 12.0,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.8,
                                  color: colors.accent,
                                ),
                              ),
                            ),
                            const SizedBox(height: 10.0),
                            Text(
                              '$firstName, your $days-day stretching plan is ready.',
                              style: GoogleFonts.bricolageGrotesque(
                                fontSize: 18.0,
                                fontWeight: FontWeight.w700,
                                color: colors.ink,
                              ),
                            ),
                            const SizedBox(height: 6.0),
                            Text(
                              overview.summary.isNotEmpty
                                  ? overview.summary
                                  : 'Tailored specifically to your goals, pain areas, and schedule.',
                              style: GoogleFonts.figtree(
                                fontSize: 14.0,
                                color: colors.ink2,
                                height: 1.35,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),

        // Right details list
        Expanded(
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: formWidth),
                    child: ListView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20.0,
                        vertical: 24.0,
                      ),
                      children: [
                        Text(
                          'YOUR SCHEDULE',
                          style: GoogleFonts.figtree(
                            fontSize: 14.0,
                            fontWeight: FontWeight.w700,
                            color: colors.accent,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 6.0),
                        Text(
                          days == 1
                              ? '1-day routine'
                              : '$days-day flexibility plan',
                          style: GoogleFonts.bricolageGrotesque(
                            fontSize: 28.0,
                            fontWeight: FontWeight.w700,
                            color: colors.ink,
                            height: 1.15,
                          ),
                        ),
                        const SizedBox(height: 8.0),
                        Text(
                          overview.summary.isNotEmpty
                              ? overview.summary
                              : days == 1
                              ? 'One routine, repeated each day.'
                              : 'A different routine each day. After day $days it starts again from day 1.',
                          style: GoogleFonts.figtree(
                            fontSize: 15.0,
                            color: colors.ink2,
                            height: 1.45,
                          ),
                        ),
                        const SizedBox(height: 20.0),
                        AppCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.auto_awesome_rounded,
                                    color: colors.accent,
                                    size: 20.0,
                                  ),
                                  const SizedBox(width: 8.0),
                                  Text(
                                    'Why this plan',
                                    style: GoogleFonts.figtree(
                                      fontSize: 18.0,
                                      fontWeight: FontWeight.w700,
                                      color: colors.ink,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14.0),
                              AppReasonList(items: reasons),
                            ],
                          ),
                        ),
                        for (final day in overview.days) ...[
                          const SizedBox(height: 16.0),
                          PlanDayCard(day: day),
                        ],
                      ],
                    ),
                  ),
                ),
              ),

              // Bottom action buttons: Stacked cleanly full-width
              Padding(
                padding: const EdgeInsets.fromLTRB(20.0, 12.0, 20.0, 24.0),
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: formWidth),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        height: 52.0,
                        child: AppButton(
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
                      ),
                      const SizedBox(height: 8.0),
                      AppButton(
                        label: 'Look around first',
                        variant: AppButtonVariant.text,
                        size: AppButtonSize.small,
                        isExpanded: false,
                        onPressed: () =>
                            ref.read(appFlowProvider.notifier).enterApp(),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Tablet portrait layout: Centered single column.
  Widget _buildTabletPortrait({
    required BuildContext context,
    required WidgetRef ref,
    required String firstName,
    required int days,
    required List<String> reasons,
    required BoxConstraints constraints,
  }) {
    final formWidth = (constraints.maxWidth * 0.85).clamp(420.0, 520.0);

    return Column(
      children: [
        Expanded(
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: formWidth),
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24.0,
                  vertical: 24.0,
                ),
                children: [
                  AppPageHeader(
                    eyebrow: 'Your plan is ready',
                    title: days == 1
                        ? '$firstName, you got a 1-day plan.'
                        : '$firstName, you got a $days-day plan.',
                  ),
                  const SizedBox(height: 8.0),
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
                  const SizedBox(height: 20.0),
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Why this plan', style: AppTextStyle.titleMedium),
                        const SizedBox(height: 12.0),
                        AppReasonList(items: reasons),
                      ],
                    ),
                  ),
                  for (final day in overview.days) ...[
                    const SizedBox(height: 16.0),
                    PlanDayCard(day: day),
                  ],
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: formWidth),
            child: Column(
              children: [
                SizedBox(
                  height: 52.0,
                  child: AppButton(
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
                ),
                const SizedBox(height: 8.0),
                AppButton(
                  label: 'Look around first',
                  variant: AppButtonVariant.text,
                  onPressed: () =>
                      ref.read(appFlowProvider.notifier).enterApp(),
                ),
              ],
            ),
          ),
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
    final size = MediaQuery.sizeOf(context);
    final isTablet = size.width >= 600;

    final eyebrowSize = isTablet ? 12.0 : null;
    final titleSize = isTablet ? 16.0 : null;
    final reasonSize = isTablet ? 14.0 : null;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Day ${day.day} · ${routine.durationText} · ${routine.stretches.length} stretches',
                  style: AppTextStyle.eyebrow.copyWith(
                    color: colors.ink3,
                    fontSize: eyebrowSize,
                  ),
                ),
              ),
              if (day.isToday)
                const AppTag(label: 'Today', tone: AppTone.accent),
            ],
          ),
          (isTablet ? 6.0 : 2.0).verticalSpace,
          Text(
            routine.name,
            style: AppTextStyle.display(22).copyWith(
              fontSize: titleSize,
            ),
          ),
          if (day.reason.isNotEmpty) ...[
            (isTablet ? 6.0 : 4.0).verticalSpace,
            Text(
              day.reason,
              style: AppTextStyle.bodySmall.copyWith(
                color: colors.ink2,
                fontSize: reasonSize,
              ),
            ),
          ] else if (routine.blurb != null &&
              routine.blurb!.trim().isNotEmpty) ...[
            (isTablet ? 6.0 : 4.0).verticalSpace,
            Text(
              routine.blurb!,
              style: AppTextStyle.bodySmall.copyWith(
                color: colors.ink2,
                fontSize: reasonSize,
              ),
            ),
          ],
          (isTablet ? 16.0 : 12.0).verticalSpace,
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                for (final stretch in routine.stretches) ...[
                  StretchThumbnail(
                    stretch: stretch,
                    size: isTablet ? AppThumbSize.large : AppThumbSize.medium,
                  ),
                  (isTablet ? 10.0 : 6.0).horizontalSpace,
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
