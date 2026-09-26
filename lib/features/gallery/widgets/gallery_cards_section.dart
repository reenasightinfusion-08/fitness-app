import 'package:flutter/material.dart';

import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:fitness_app/core/theme/theme.dart';
import 'package:fitness_app/core/widgets/widgets.dart';

class GalleryCardsSection extends StatelessWidget {
  const GalleryCardsSection({super.key});

  @override
  Widget build(BuildContext context) => AppSectionWrapper(
    title: 'Cards & content',
    actionLabel: 'See all',
    onAction: () {},
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const GalleryTodayPlanCard(),
        12.verticalSpace,
        AppRoutineCard(
          title: 'Desk reset',
          meta: '8 min · 6 stretches · Standing → Seated',
          badge: 'Adapted for you · 2 swaps',
          onTap: () {},
        ),
        10.verticalSpace,
        AppRoutineCard(
          title: 'Splits program',
          meta: '20 min · 12 stretches · Floor',
          isLocked: true,
          onTap: () {},
        ),
        12.verticalSpace,
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10.h,
          crossAxisSpacing: 10.w,
          childAspectRatio: 1.35,
          children: [
            AppTileCard(title: 'Morning', meta: '6 min', onTap: () {}),
            AppTileCard(title: 'Desk break', meta: '4 min', onTap: () {}),
          ],
        ),
        12.verticalSpace,
        Row(
          children: [
            const Expanded(
              child: AppFactTile(label: 'Time', value: '10 min'),
            ),
            8.horizontalSpace,
            const Expanded(
              child: AppFactTile(label: 'Level', value: 'Beginner'),
            ),
            8.horizontalSpace,
            const Expanded(
              child: AppFactTile(label: 'Position', value: 'Floor'),
            ),
          ],
        ),
        12.verticalSpace,
        const AppNote(
          title: 'Starting level: Beginner',
          message: 'Retake the check any time from Progress.',
        ),
        10.verticalSpace,
        const AppNote(
          tone: AppTone.warm,
          message: 'No strap? A towel or belt works.',
        ),
        10.verticalSpace,
        const AppNote(
          tone: AppTone.danger,
          message: 'Please check with a doctor before stretching your knee.',
        ),
        12.verticalSpace,
        const AppEmptyState(
          icon: Icons.bookmark_border_rounded,
          title: 'No saved routines yet',
          message: 'Build your own from any stretches, in any order.',
          actionLabel: 'New routine',
        ),
      ],
    ),
  );
}

class GalleryTodayPlanCard extends StatelessWidget {
  const GalleryTodayPlanCard({super.key});

  @override
  Widget build(BuildContext context) => AppCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'TODAY’S PLAN · 10 MIN',
          style: AppTextStyle.eyebrow.copyWith(color: context.colors.ink3),
        ),
        4.verticalSpace,
        Text('Hips & lower back', style: AppTextStyle.titleLarge),
        14.verticalSpace,
        Row(
          children: [
            for (var i = 0; i < 4; i++) ...[
              const AppThumb(),
              6.horizontalSpace,
            ],
            Text(
              '+3',
              style: AppTextStyle.bodySmall.copyWith(
                fontWeight: FontWeight.w700,
                color: context.colors.ink2,
              ),
            ),
          ],
        ),
        14.verticalSpace,
        Wrap(
          spacing: 6.w,
          runSpacing: 6.h,
          children: const [
            AppTag(label: 'Desk hips', tone: AppTone.accent),
            AppTag(label: 'No kneeling', tone: AppTone.accent),
            AppTag(label: 'Premium', icon: Icons.lock_rounded),
          ],
        ),
        14.verticalSpace,
        Row(
          children: [
            Expanded(
              child: AppButton(
                label: 'Start',
                icon: Icons.play_arrow_rounded,
                onPressed: () {},
              ),
            ),
            10.horizontalSpace,
            Expanded(
              child: AppButton(
                label: 'See stretches',
                variant: AppButtonVariant.secondary,
                onPressed: () {},
              ),
            ),
          ],
        ),
      ],
    ),
  );
}
