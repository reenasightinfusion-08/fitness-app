import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:fitness_app/core/theme/theme.dart';
import 'package:fitness_app/core/widgets/widgets.dart';
import 'package:fitness_app/features/onboarding_setup/models/onboarding_options.dart';
import 'package:fitness_app/features/onboarding_setup/models/onboarding_profile.dart';
import 'package:fitness_app/features/onboarding_setup/onboarding_setup_screen.dart';
import 'package:fitness_app/features/onboarding_setup/providers/onboarding_profile_provider.dart';

/// Matches the prototype's `screens.editprofile`: every answer from the
/// 10-step setup, editable one row at a time. Tapping a row jumps into
/// that single step of [OnboardingSetupScreen] in edit mode; nothing here
/// changes the profile directly.
class EditProfileScreen extends ConsumerWidget {
  const EditProfileScreen({super.key});

  void _openStep(BuildContext context, int step) => Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => OnboardingSetupScreen(editStepIndex: step),
    ),
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final p = ref.watch(onboardingProfileProvider);
    final rows = _rows(p);

    return Scaffold(
      backgroundColor: colors.ground,
      appBar: AppTopBar(
        title: 'Edit profile',
        onBack: () => Navigator.of(context).pop(),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: AppInsets.page,
          children: [
            Text(
              "Change anything. Your daily plan updates straight away.",
              style: AppTextStyle.bodyMedium.copyWith(color: colors.ink2),
            ),
            16.verticalSpace,
            AppCard(
              variant: AppCardVariant.list,
              child: Column(
                children: [
                  for (final row in rows)
                    AppSettingRow(
                      title: row.label,
                      subtitle: row.value,
                      onTap: () => _openStep(context, row.step),
                      showDivider: row != rows.last,
                    ),
                ],
              ),
            ),
            20.verticalSpace,
            Text('Stretches you said hurt', style: AppTextStyle.sectionTitle),
            10.verticalSpace,
            const AppEmptyState(
              icon: Icons.info_outline_rounded,
              title: 'None yet',
              message:
                  "After a session, mark anything that hurt and we'll "
                  'leave it out of your plans.',
            ),
          ],
        ),
      ),
    );
  }

  List<_ProfileRow> _rows(OnboardingProfile p) {
    final lifestyle = p.lifestyle == null
        ? null
        : lifestyleOptions.firstWhere((o) => o.id == p.lifestyle);
    final dayValue = [
      if (lifestyle != null) lifestyle.label,
      if (p.sports.isNotEmpty) p.sports.join(', '),
    ].join(' · ');

    final goalsValue = p.goals
        .map((id) => goalOptions.firstWhere((g) => g.id == id).label)
        .join(', ');

    final painValue = p.painAreas.map((id) => painAreaLabels[id]).join(', ');

    final limits = <String>[
      if (p.noKneel) 'No kneeling',
      if (p.noFloor) 'No floor',
      if (p.hadRecentSurgery) 'Recent surgery',
      if (p.isPregnant) 'Pregnant',
      for (final entry in p.injurySeverity.entries)
        '${injuryAreaLabels[entry.key]} (${entry.value.name})',
    ];

    final equipValue = p.equipmentNone
        ? 'None'
        : p.equipment.map((id) => equipmentLabels[id]).join(', ');

    final level = calcFlexibilityLevel(p.flexAnswers);

    return [
      _ProfileRow(
        0,
        'Name, age & country',
        [p.name, if (p.age.isNotEmpty) '${p.age} yrs', if (p.country.isNotEmpty) p.country]
            .where((s) => s.isNotEmpty)
            .join(' · '),
        fallback: 'Not set',
      ),
      _ProfileRow(
        1,
        'Height & weight',
        (p.heightCm.isEmpty && p.weightKg.isEmpty)
            ? ''
            : '${p.heightCm.isEmpty ? '?' : p.heightCm} cm · '
                  '${p.weightKg.isEmpty ? '?' : p.weightKg} kg',
        fallback: 'Not set',
      ),
      _ProfileRow(2, 'Your day', dayValue, fallback: 'Not set'),
      _ProfileRow(3, 'Goals', goalsValue, fallback: 'Not set'),
      _ProfileRow(4, 'Tight or sore areas', painValue, fallback: 'None'),
      _ProfileRow(5, 'Injuries & limits', limits.join(', '), fallback: 'None'),
      _ProfileRow(6, 'Equipment', equipValue, fallback: 'Not set'),
      _ProfileRow(
        7,
        'Flexibility level',
        flexibilityLevelLabels[level],
        fallback: 'Not set',
      ),
      _ProfileRow(
        8,
        'Time per day',
        '${p.minutesPerDay} min'
            '${p.timeOfDay != null ? ' · ${p.timeOfDay}' : ''}',
        fallback: 'Not set',
      ),
    ];
  }
}

class _ProfileRow {
  const _ProfileRow(this.step, this.label, this.rawValue, {this.fallback = ''});

  final int step;
  final String label;
  final String rawValue;
  final String fallback;

  String get value => rawValue.trim().isEmpty ? fallback : rawValue;
}
