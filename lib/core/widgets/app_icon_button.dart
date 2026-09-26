import 'package:flutter/material.dart';

import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:fitness_app/core/theme/theme.dart';

/// 42×42 square icon button. With [activeIcon] it becomes a toggle (e.g. favourite).
class AppIconButton extends StatelessWidget {
  const AppIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    required this.tooltip,
    this.activeIcon,
    this.isActive = false,
    this.color,
    this.activeColor,
    this.isOnDark = false,
  });

  final IconData icon;
  final IconData? activeIcon;
  final VoidCallback? onPressed;
  final String tooltip;
  final bool isActive;
  final Color? color;
  final Color? activeColor;
  final bool isOnDark;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final baseColor = color ?? (isOnDark ? colors.playerInk : colors.ink);
    final showActive = isActive && activeIcon != null;

    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        borderRadius: AppBorderRadius.md,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          hoverColor: isOnDark
              ? colors.playerInk.withValues(alpha: 0.08)
              : colors.surface2,
          child: SizedBox.square(
            dimension: 42.r,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              transitionBuilder: (child, animation) =>
                  ScaleTransition(scale: animation, child: child),
              child: Icon(
                showActive ? activeIcon : icon,
                key: ValueKey(showActive),
                size: 22.r,
                color: showActive ? (activeColor ?? colors.danger) : baseColor,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
