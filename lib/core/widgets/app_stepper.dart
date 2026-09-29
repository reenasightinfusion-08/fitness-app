import 'package:flutter/material.dart';

import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:fitness_app/core/theme/theme.dart';

/// − value + control. Touch targets are 36 (prototype had 30, too small for thumbs).
class AppStepper extends StatelessWidget {
  const AppStepper({
    super.key,
    required this.valueLabel,
    required this.onDecrement,
    required this.onIncrement,
    this.isTransparent = false,
  });

  final String valueLabel;
  final VoidCallback? onDecrement;
  final VoidCallback? onIncrement;
  final bool isTransparent;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: EdgeInsets.all(2.r),
      decoration: BoxDecoration(
        color: colors.surface2,
        borderRadius: AppBorderRadius.sm,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppStepperButton(
            icon: Icons.remove_rounded,
            tooltip: 'Decrease',
            onTap: onDecrement,
            isTransparent: isTransparent,
          ),
          ConstrainedBox(
            constraints: BoxConstraints(minWidth: 44.w),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 150),
              child: Text(
                valueLabel,
                key: ValueKey(valueLabel),
                textAlign: TextAlign.center,
                style: AppTextStyle.numeric,
              ),
            ),
          ),
          AppStepperButton(
            icon: Icons.add_rounded,
            tooltip: 'Increase',
            onTap: onIncrement,
            isTransparent: isTransparent,
          ),
        ],
      ),
    );
  }
}

class AppStepperButton extends StatelessWidget {
  const AppStepperButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.isTransparent = false,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;
  final bool isTransparent;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final bgColor = isTransparent
        ? Colors.transparent
        : (onTap == null ? Colors.transparent : colors.surface);

    return Tooltip(
      message: tooltip,
      child: Material(
        color: bgColor,
        borderRadius: AppBorderRadius.xs,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppBorderRadius.xs,
          child: SizedBox.square(
            dimension: 36.r,
            child: Icon(
              icon,
              size: 18.r,
              color: onTap == null ? colors.ink3 : colors.ink,
            ),
          ),
        ),
      ),
    );
  }
}
