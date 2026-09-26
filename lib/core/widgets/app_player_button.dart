import 'package:flutter/material.dart';

import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:fitness_app/core/theme/theme.dart';

/// Round control on the dark player (back, pause/play, +15s, skip).
class AppPlayerButton extends StatelessWidget {
  const AppPlayerButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.label,
    this.isPrimary = false,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;
  final String? label;
  final bool isPrimary;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final dimension = isPrimary ? 76.r : 56.r;
    final foreground = isPrimary ? colors.playerBg : colors.playerInk;

    return Tooltip(
      message: tooltip,
      child: Material(
        color: isPrimary
            ? colors.playerInk
            : colors.playerInk.withValues(alpha: 0.09),
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: SizedBox.square(
            dimension: dimension,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  transitionBuilder: (child, animation) =>
                      ScaleTransition(scale: animation, child: child),
                  child: Icon(
                    icon,
                    key: ValueKey(icon),
                    size: isPrimary ? 34.r : 22.r,
                    color: foreground,
                  ),
                ),
                if (label != null)
                  Text(
                    label!,
                    style: AppTextStyle.tab.copyWith(
                      color: foreground,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
