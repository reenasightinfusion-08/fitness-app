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
    final size = MediaQuery.sizeOf(context);
    final isTablet = size.width >= 600;
    final h = size.height;

    final minH = isTablet
        ? (h * (isCompact ? 0.052 : 0.068)).clamp(50.0, 76.0)
        : (isCompact ? 34.h : 40.h);
    final padH = isTablet
        ? (h * (isCompact ? 0.022 : 0.030)).clamp(20.0, 38.0)
        : (isCompact ? 12.w : 14.w);
    final padV = isTablet
        ? (h * (isCompact ? 0.014 : 0.018)).clamp(12.0, 22.0)
        : 8.h;
    final chipFontSize = isTablet
        ? (h * (isCompact ? 0.020 : 0.026)).clamp(isCompact ? 16.0 : 19.0, 28.0)
        : null;
    final iconSize = isTablet
        ? (h * 0.028).clamp(20.0, 32.0)
        : 16.r;

    return Semantics(
      button: true,
      selected: isSelected,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        constraints: BoxConstraints(minHeight: minH),
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
              padding: EdgeInsets.symmetric(horizontal: padH, vertical: padV),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedSize(
                    duration: const Duration(milliseconds: 180),
                    child: (isSelected && showCheck)
                        ? Padding(
                            padding: EdgeInsets.only(
                              right: isTablet ? 8.0 : 6.w,
                            ),
                            child: Icon(
                              Icons.check_rounded,
                              size: iconSize,
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
                          fontSize: chipFontSize,
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
