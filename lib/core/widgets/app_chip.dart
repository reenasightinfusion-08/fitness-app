import 'package:flutter/material.dart';

import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:fitness_app/core/theme/theme.dart';

/// Filter / multi-select pill. Selected state gets a check so it reads
/// without relying on color alone.
class AppChip extends StatelessWidget {
  const AppChip({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.isCompact = false,
    this.showCheck = true,
  });

  final String label;
  final bool isSelected;
  final VoidCallback? onTap;
  final bool isCompact;

  /// Set false for a chip whose label is already the whole content (a
  /// single letter, an icon) — the check mark would just crowd it, and
  /// the fill color alone is enough to read as selected there.
  final bool showCheck;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final foreground = isSelected ? colors.accentInk : colors.ink;

    return Semantics(
      button: true,
      selected: isSelected,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        constraints: BoxConstraints(minHeight: isCompact ? 34.h : 40.h),
        decoration: BoxDecoration(
          color: isSelected ? colors.accent : colors.surface,
          borderRadius: AppBorderRadius.pill,
          border: Border.all(color: isSelected ? colors.accent : colors.line),
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: onTap,
            borderRadius: AppBorderRadius.pill,
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isCompact ? 12.w : 14.w,
                vertical: 8.h,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedSize(
                    duration: const Duration(milliseconds: 180),
                    child: (isSelected && showCheck)
                        ? Padding(
                            padding: EdgeInsets.only(right: 6.w),
                            child: Icon(
                              Icons.check_rounded,
                              size: 16.r,
                              color: foreground,
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),
                  Text(
                    label,
                    style: (isCompact ? AppTextStyle.meta : AppTextStyle.chip)
                        .copyWith(
                          color: foreground,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
