import 'package:flutter/material.dart';

import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:fitness_app/core/theme/theme.dart';

/// Story-style segments across the top of the player: one per stretch.
class AppSegmentProgress extends StatelessWidget {
  const AppSegmentProgress({
    super.key,
    required this.total,
    required this.currentIndex,
  });

  final int total;
  final int currentIndex;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Semantics(
      label: 'Stretch ${currentIndex + 1} of $total',
      excludeSemantics: true,
      child: Row(
        children: [
          for (var i = 0; i < total; i++) ...[
            if (i > 0) 4.horizontalSpace,
            Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                height: 4.h,
                decoration: BoxDecoration(
                  borderRadius: AppBorderRadius.pill,
                  color: i < currentIndex
                      ? colors.playerDim
                      : i == currentIndex
                      ? colors.playerInk
                      : colors.playerInk.withValues(alpha: 0.16),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
