import 'package:flutter/material.dart';

import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:fitness_app/core/theme/theme.dart';

/// The active dot "stretches" into a pill.
class StretchPageIndicator extends StatelessWidget {
  const StretchPageIndicator({
    super.key,
    required this.count,
    required this.currentIndex,
  });

  final int count;
  final int currentIndex;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Semantics(
      label: 'Page ${currentIndex + 1} of $count',
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < count; i++) ...[
            if (i > 0) 6.horizontalSpace,
            AnimatedContainer(
              duration: const Duration(milliseconds: 320),
              curve: Curves.easeOutBack,
              width: i == currentIndex ? 28.w : 8.w,
              height: 8.r,
              decoration: BoxDecoration(
                color: i == currentIndex ? colors.accent : colors.line,
                borderRadius: AppBorderRadius.pill,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
