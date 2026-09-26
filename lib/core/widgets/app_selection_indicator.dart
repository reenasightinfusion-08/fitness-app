import 'package:flutter/material.dart';

import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:fitness_app/core/theme/theme.dart';

enum AppSelectionShape { radio, checkbox }

/// Radio dot for single choice, rounded checkbox for multi choice.
class AppSelectionIndicator extends StatelessWidget {
  const AppSelectionIndicator({
    super.key,
    required this.isSelected,
    this.shape = AppSelectionShape.radio,
  });

  final bool isSelected;
  final AppSelectionShape shape;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isRadio = shape == AppSelectionShape.radio;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      width: 22.r,
      height: 22.r,
      decoration: BoxDecoration(
        shape: isRadio ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: isRadio ? null : BorderRadius.circular(7.r),
        color: isSelected && !isRadio ? colors.accent : colors.surface,
        border: Border.all(
          color: isSelected ? colors.accent : colors.line,
          width: 2,
        ),
      ),
      alignment: Alignment.center,
      child: AnimatedScale(
        scale: isSelected ? 1 : 0,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutBack,
        child: isRadio
            ? Container(
                width: 10.r,
                height: 10.r,
                decoration: BoxDecoration(
                  color: colors.accent,
                  shape: BoxShape.circle,
                ),
              )
            : Icon(Icons.check_rounded, size: 15.r, color: colors.accentInk),
      ),
    );
  }
}
