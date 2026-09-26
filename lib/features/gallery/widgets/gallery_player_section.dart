import 'package:flutter/material.dart';

import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:fitness_app/core/theme/theme.dart';
import 'package:fitness_app/core/widgets/widgets.dart';

class GalleryPlayerSection extends StatefulWidget {
  const GalleryPlayerSection({super.key});

  @override
  State<GalleryPlayerSection> createState() => GalleryPlayerSectionState();
}

class GalleryPlayerSectionState extends State<GalleryPlayerSection> {
  bool isPaused = false;
  int currentIndex = 2;

  static const int stretchCount = 6;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return AppSectionWrapper(
      title: 'Player',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppResumeBanner(
            title: 'Desk reset',
            subtitle: 'Stretch 3 of 6: Seated twist',
            onResume: () {},
          ),
          12.verticalSpace,
          Container(
            padding: EdgeInsets.fromLTRB(14.w, 14.h, 14.w, 16.h),
            decoration: BoxDecoration(
              color: colors.playerBg,
              borderRadius: AppBorderRadius.hero,
            ),
            child: Column(
              children: [
                AppSegmentProgress(
                  total: stretchCount,
                  currentIndex: currentIndex,
                ),
                20.verticalSpace,
                Text(
                  'HOLD · LEFT SIDE',
                  style: AppTextStyle.eyebrow.copyWith(color: colors.playerDim),
                ),
                4.verticalSpace,
                Text(
                  'Seated twist',
                  style: AppTextStyle.headline.copyWith(
                    color: colors.playerInk,
                  ),
                ),
                12.verticalSpace,
                Text(
                  '0:24',
                  style: AppTextStyle.timer.copyWith(color: colors.playerInk),
                ),
                20.verticalSpace,
                AppProgressBar(
                  value: 0.6,
                  height: 3,
                  color: colors.warm,
                  trackColor: colors.playerInk.withValues(alpha: 0.12),
                ),
                20.verticalSpace,
                GalleryPlayerControls(
                  isPaused: isPaused,
                  onBack: currentIndex > 0
                      ? () => setState(() => currentIndex--)
                      : null,
                  onTogglePause: () => setState(() => isPaused = !isPaused),
                  onSkip: currentIndex < stretchCount - 1
                      ? () => setState(() => currentIndex++)
                      : null,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class GalleryPlayerControls extends StatelessWidget {
  const GalleryPlayerControls({
    super.key,
    required this.isPaused,
    required this.onBack,
    required this.onTogglePause,
    required this.onSkip,
  });

  final bool isPaused;
  final VoidCallback? onBack;
  final VoidCallback onTogglePause;
  final VoidCallback? onSkip;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      AppPlayerButton(
        icon: Icons.skip_previous_rounded,
        label: 'Back',
        tooltip: 'Previous stretch',
        onTap: onBack,
      ),
      AppPlayerButton(
        icon: Icons.add_rounded,
        label: '15s',
        tooltip: 'Add 15 seconds',
        onTap: () {},
      ),
      AppPlayerButton(
        icon: isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
        tooltip: isPaused ? 'Resume' : 'Pause',
        isPrimary: true,
        onTap: onTogglePause,
      ),
      AppPlayerButton(
        icon: Icons.swap_horiz_rounded,
        label: 'Swap',
        tooltip: 'Swap stretch',
        onTap: () {},
      ),
      AppPlayerButton(
        icon: Icons.skip_next_rounded,
        label: 'Skip',
        tooltip: 'Next stretch',
        onTap: onSkip,
      ),
    ],
  );
}
