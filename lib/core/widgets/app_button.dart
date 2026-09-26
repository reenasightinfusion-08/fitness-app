import 'package:flutter/material.dart';

import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:fitness_app/core/theme/theme.dart';
import 'package:fitness_app/core/widgets/app_loader.dart';

enum AppButtonVariant { primary, secondary, text, danger, dangerText, inverse }

enum AppButtonSize { regular, small }

class AppButton extends StatefulWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.size = AppButtonSize.regular,
    this.icon,
    this.isLoading = false,
    this.isExpanded = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final AppButtonSize size;
  final IconData? icon;
  final bool isLoading;
  final bool isExpanded;

  @override
  State<AppButton> createState() => AppButtonState();
}

class AppButtonState extends State<AppButton> {
  bool isPressed = false;

  bool get isEnabled => widget.onPressed != null && !widget.isLoading;
  bool get isSmall => widget.size == AppButtonSize.small;

  ({Color background, Color foreground, Color? border}) resolvePalette(
    AppColors colors,
  ) => switch (widget.variant) {
    AppButtonVariant.primary => (
      background: colors.accent,
      foreground: colors.accentInk,
      border: null,
    ),
    AppButtonVariant.secondary => (
      background: colors.surface,
      foreground: colors.ink,
      border: colors.line,
    ),
    AppButtonVariant.text => (
      background: Colors.transparent,
      foreground: colors.accent,
      border: null,
    ),
    AppButtonVariant.danger => (
      background: colors.danger,
      foreground: AppColors.white,
      border: null,
    ),
    AppButtonVariant.dangerText => (
      background: Colors.transparent,
      foreground: colors.danger,
      border: null,
    ),
    AppButtonVariant.inverse => (
      background: colors.playerInk,
      foreground: colors.playerBg,
      border: null,
    ),
  };

  @override
  Widget build(BuildContext context) {
    final palette = resolvePalette(context.colors);
    final radius = isSmall ? AppBorderRadius.md : AppBorderRadius.xl;
    final minHeight = switch ((widget.size, widget.variant)) {
      (AppButtonSize.small, _) => 38.h,
      (_, AppButtonVariant.text || AppButtonVariant.dangerText) => 44.h,
      _ => 52.h,
    };

    return Semantics(
      button: true,
      enabled: isEnabled,
      child: AnimatedOpacity(
        opacity: widget.onPressed == null ? 0.4 : 1,
        duration: const Duration(milliseconds: 150),
        child: AnimatedScale(
          scale: isPressed ? 0.975 : 1,
          duration: const Duration(milliseconds: 90),
          child: Material(
            color: palette.background,
            shape: RoundedRectangleBorder(
              borderRadius: radius,
              side: palette.border == null
                  ? BorderSide.none
                  : BorderSide(color: palette.border!),
            ),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: isEnabled ? widget.onPressed : null,
              onHighlightChanged: (value) => setState(() => isPressed = value),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: minHeight,
                  minWidth: widget.isExpanded ? double.infinity : 0,
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isSmall ? 14.w : 18.w,
                  ),
                  child: AppButtonContent(
                    label: widget.label,
                    icon: widget.icon,
                    isLoading: widget.isLoading,
                    color: palette.foreground,
                    isSmall: isSmall,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class AppButtonContent extends StatelessWidget {
  const AppButtonContent({
    super.key,
    required this.label,
    required this.icon,
    required this.isLoading,
    required this.color,
    required this.isSmall,
  });

  final String label;
  final IconData? icon;
  final bool isLoading;
  final Color color;
  final bool isSmall;

  @override
  Widget build(BuildContext context) {
    final style = (isSmall ? AppTextStyle.buttonSmall : AppTextStyle.button)
        .copyWith(color: color);
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isLoading)
          AppLoader(size: 18, strokeWidth: 2, color: color)
        else if (icon != null)
          Icon(icon, size: 20.r, color: color),
        if (isLoading || icon != null) 8.horizontalSpace,
        Flexible(
          child: Text(
            label,
            style: style,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
