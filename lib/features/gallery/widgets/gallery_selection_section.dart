import 'package:flutter/material.dart';

import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:fitness_app/core/widgets/widgets.dart';

class GallerySelectionSection extends StatefulWidget {
  const GallerySelectionSection({super.key});

  @override
  State<GallerySelectionSection> createState() =>
      GallerySelectionSectionState();
}

class GallerySelectionSectionState extends State<GallerySelectionSection> {
  static const List<String> sports = [
    'Running',
    'Gym',
    'Cycling',
    'Cricket',
    'Yoga',
    'Swimming',
  ];
  static const List<String> areas = [
    'All',
    'Neck',
    'Shoulders',
    'Hips',
    'Hamstrings',
    'Lower back',
    'Calves',
  ];

  final Set<String> selectedSports = {'Running'};
  String selectedArea = 'All';
  String lifestyle = 'desk';
  final Set<String> goals = {'flexibility'};
  bool isReminderOn = true;
  bool noKneeling = false;
  bool isSafetyAccepted = false;
  int minutes = 10;
  String severity = 'moderate';
  int holdSeconds = 30;

  void toggle<T>(Set<T> set, T value) =>
      setState(() => set.contains(value) ? set.remove(value) : set.add(value));

  @override
  Widget build(BuildContext context) => AppSectionWrapper(
    title: 'Selection',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const AppFieldLabel(text: 'Sports you play', isOptional: true),
        8.verticalSpace,
        AppChipGroup(
          children: [
            for (final sport in sports)
              AppChip(
                label: sport,
                isSelected: selectedSports.contains(sport),
                onTap: () => toggle(selectedSports, sport),
              ),
          ],
        ),
        16.verticalSpace,
        AppChipGroup(
          isScrollable: true,
          children: [
            for (final area in areas)
              AppChip(
                label: area,
                isCompact: true,
                isSelected: selectedArea == area,
                onTap: () => setState(() => selectedArea = area),
              ),
          ],
        ),
        20.verticalSpace,
        AppOptionTile(
          title: 'Mostly sitting',
          subtitle: 'Desk job, long commutes',
          isSelected: lifestyle == 'desk',
          onTap: () => setState(() => lifestyle = 'desk'),
        ),
        10.verticalSpace,
        AppOptionTile(
          title: 'On my feet a lot',
          subtitle: 'Shop floor, teaching, caregiving',
          isSelected: lifestyle == 'feet',
          onTap: () => setState(() => lifestyle = 'feet'),
        ),
        10.verticalSpace,
        AppOptionTile(
          title: 'Get more flexible',
          shape: AppSelectionShape.checkbox,
          isSelected: goals.contains('flexibility'),
          onTap: () => toggle(goals, 'flexibility'),
        ),
        10.verticalSpace,
        AppOptionTile(
          title:
              'I understand. I’ll stretch to mild tension and stop if something hurts.',
          shape: AppSelectionShape.checkbox,
          isSelected: isSafetyAccepted,
          onTap: () => setState(() => isSafetyAccepted = !isSafetyAccepted),
        ),
        20.verticalSpace,
        AppCard(
          variant: AppCardVariant.list,
          child: Column(
            children: [
              AppSettingRow(
                title: 'Daily reminder',
                subtitle: 'Arrives even when the app is closed',
                trailing: AppSwitch(
                  value: isReminderOn,
                  semanticLabel: 'Daily reminder',
                  onChanged: (value) => setState(() => isReminderOn = value),
                ),
              ),
              AppSettingRow(
                title: 'I can’t kneel comfortably',
                trailing: AppSwitch(
                  value: noKneeling,
                  semanticLabel: 'I can’t kneel comfortably',
                  onChanged: (value) => setState(() => noKneeling = value),
                ),
              ),
              AppSettingRow(
                title: 'Hold time',
                subtitle: 'Per stretch',
                trailing: AppStepper(
                  valueLabel: '${holdSeconds}s',
                  onDecrement: holdSeconds > 15
                      ? () => setState(() => holdSeconds -= 5)
                      : null,
                  onIncrement: holdSeconds < 120
                      ? () => setState(() => holdSeconds += 5)
                      : null,
                ),
              ),
              AppSettingRow(title: 'Edit profile', onTap: () {}),
              AppSettingRow(
                title: 'Log out',
                titleColor: Theme.of(context).colorScheme.error,
                onTap: () {},
                showDivider: false,
              ),
            ],
          ),
        ),
        20.verticalSpace,
        const AppFieldLabel(text: 'Minutes per day'),
        8.verticalSpace,
        AppSegmentedControl<int>(
          segments: const [
            AppSegmentModel(value: 5, label: '5 min'),
            AppSegmentModel(value: 10, label: '10 min'),
            AppSegmentModel(value: 15, label: '15 min'),
            AppSegmentModel(value: 20, label: '20 min'),
          ],
          value: minutes,
          onChanged: (value) => setState(() => minutes = value),
        ),
        12.verticalSpace,
        AppSegmentedControl<String>(
          isCompact: true,
          segments: const [
            AppSegmentModel(value: 'mild', label: 'Mild'),
            AppSegmentModel(value: 'moderate', label: 'Moderate'),
            AppSegmentModel(value: 'serious', label: 'Serious'),
          ],
          value: severity,
          onChanged: (value) => setState(() => severity = value),
        ),
      ],
    ),
  );
}
