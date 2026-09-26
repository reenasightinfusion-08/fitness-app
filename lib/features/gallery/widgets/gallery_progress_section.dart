import 'package:flutter/material.dart';

import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:fitness_app/core/theme/theme.dart';
import 'package:fitness_app/core/widgets/widgets.dart';

class GalleryProgressSection extends StatelessWidget {
  const GalleryProgressSection({super.key});

  static const List<WeekDayModel> week = [
    WeekDayModel(label: 'M', dayOfMonth: 21, isDone: true),
    WeekDayModel(label: 'T', dayOfMonth: 22, isDone: true),
    WeekDayModel(label: 'W', dayOfMonth: 23),
    WeekDayModel(label: 'T', dayOfMonth: 24, isToday: true),
    WeekDayModel(label: 'F', dayOfMonth: 25),
    WeekDayModel(label: 'S', dayOfMonth: 26),
    WeekDayModel(label: 'S', dayOfMonth: 27),
  ];

  @override
  Widget build(BuildContext context) => AppSectionWrapper(
    title: 'Progress',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const AppPageHeader(
          eyebrow: 'Thursday, 24 Sep',
          title: 'Good afternoon, Anand',
          trailing: AppStreakBadge(days: 2),
        ),
        16.verticalSpace,
        const AppProgressBar(value: 0.4),
        16.verticalSpace,
        const AppCard(child: AppWeekStrip(days: week)),
        12.verticalSpace,
        Row(
          children: [
            const Expanded(
              child: AppStatTile(value: '14', label: 'Sessions'),
            ),
            8.horizontalSpace,
            const Expanded(
              child: AppStatTile(value: '126', label: 'Minutes'),
            ),
            8.horizontalSpace,
            const Expanded(
              child: AppStatTile(value: '5', label: 'Best streak'),
            ),
          ],
        ),
        12.verticalSpace,
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('September', style: AppTextStyle.titleMedium),
              12.verticalSpace,
              const AppCalendarGrid(
                leadingBlankDays: 1,
                dayCount: 30,
                completedDays: {2, 3, 5, 8, 9, 10, 11, 15, 16, 19, 21, 22},
                today: 24,
              ),
            ],
          ),
        ),
        12.verticalSpace,
        AppCard(
          child: Row(
            children: [
              const AppAvatar(name: 'Anand Patel'),
              14.horizontalSpace,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Anand Patel', style: AppTextStyle.titleMedium),
                    Text(
                      'Free plan · Beginner',
                      style: AppTextStyle.meta.copyWith(
                        color: context.colors.ink2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        12.verticalSpace,
        const AppCard(
          child: AppReasonList(
            items: [
              'Hips and chest first — they tighten most on desk days.',
              'No kneeling stretches, as you asked.',
              'Ends lying down to help you wind down.',
            ],
          ),
        ),
      ],
    ),
  );
}
