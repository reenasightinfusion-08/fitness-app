import 'package:flutter/material.dart';

import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:fitness_app/core/theme/theme.dart';

class AppSegmentModel<T> {
  const AppSegmentModel({required this.value, required this.label});

  final T value;
  final String label;
}

/// iOS-style segmented control with a sliding thumb.
class AppSegmentedControl<T> extends StatelessWidget {
  const AppSegmentedControl({
    super.key,
    required this.segments,
    required this.value,
    required this.onChanged,
    this.isCompact = false,
  });

  final List<AppSegmentModel<T>> segments;
  final T? value;
  final ValueChanged<T> onChanged;
  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final selectedIndex = segments.indexWhere(
      (segment) => segment.value == value,
    );
    final alignmentX = segments.length < 2
        ? 0.0
        : -1 + 2 * selectedIndex / (segments.length - 1);

    return Container(
      height: isCompact ? 36.h : 44.h,
      padding: EdgeInsets.all(3.r),
      decoration: BoxDecoration(
        color: colors.surface2,
        borderRadius: AppBorderRadius.md,
      ),
      child: Stack(
        children: [
          if (selectedIndex >= 0)
            AnimatedAlign(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              alignment: Alignment(alignmentX, 0),
              child: FractionallySizedBox(
                widthFactor: 1 / segments.length,
                heightFactor: 1,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: AppBorderRadius.sm,
                    boxShadow: AppShadows.lifted(colors),
                  ),
                ),
              ),
            ),
          Row(
            children: [
              for (final segment in segments)
                Expanded(
                  child: AppSegmentButton(
                    label: segment.label,
                    isSelected: segment.value == value,
                    isCompact: isCompact,
                    onTap: () => onChanged(segment.value),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class AppSegmentButton extends StatelessWidget {
  const AppSegmentButton({
    super.key,
    required this.label,
    required this.isSelected,
    required this.isCompact,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final bool isCompact;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Semantics(
      button: true,
      selected: isSelected,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppBorderRadius.sm,
        child: Center(
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 180),
            style: (isCompact ? AppTextStyle.meta : AppTextStyle.chip).copyWith(
              color: isSelected ? colors.ink : colors.ink2,
              fontWeight: FontWeight.w600,
            ),
            child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
        ),
      ),
    );
  }
}
