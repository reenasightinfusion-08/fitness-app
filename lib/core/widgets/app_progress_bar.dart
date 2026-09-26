import 'package:flutter/material.dart';

import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:fitness_app/core/theme/theme.dart';

/// Determinate progress (onboarding steps, player hold time). Animates between values.
class AppProgressBar extends StatelessWidget {
  const AppProgressBar({
    super.key,
    required this.value,
    this.height = 5,
    this.color,
    this.trackColor,
  });

  final double value;
  final double height;
  final Color? color;
  final Color? trackColor;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Semantics(
      value: '${(value * 100).round()}%',
      child: ClipRRect(
        borderRadius: AppBorderRadius.pill,
        child: Container(
          height: height.h,
          color: trackColor ?? colors.surface2,
          alignment: Alignment.centerLeft,
          child: TweenAnimationBuilder<double>(
            tween: Tween(end: value.clamp(0, 1)),
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            builder: (context, progress, child) => FractionallySizedBox(
              widthFactor: progress,
              heightFactor: 1,
              child: child,
            ),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: color ?? colors.accent,
                borderRadius: AppBorderRadius.pill,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
