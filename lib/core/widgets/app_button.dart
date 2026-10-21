import 'package:flutter/material.dart';

import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:fitness_app/core/theme/theme.dart';
import 'package:fitness_app/core/widgets/app_loader.dart';

enum AppButtonVariant {
  primary,
  secondary,
  text,
  danger,
  dangerText,
  inverse,

  /// Black with white content (white with black content in dark mode), the
  /// look Apple asks for on its sign-in button.
  contrast,
}

enum AppButtonSize { regular, small }

class AppButton extends StatefulWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.size = AppButtonSize.regular,
    this.icon,
    this.leading,
    this.isLoading = false,
    this.isExpanded = true,
    this.minHeight,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final AppButtonSize size;
  final IconData? icon;

  /// A custom widget (a brand logo, say) shown where [icon] would be.
  final Widget? leading;
  final bool isLoading;
  final bool isExpanded;
  final double? minHeight;

  @override
  State<AppButton> createState() => AppButtonState();
}

class AppButtonState extends State<AppButton> {
  bool isPressed = false;

  bool get isEnabled => widget.onPressed != null && !widget.isLoading;
  bool get isSmall => widget.size == AppButtonSize.small;

  ({Color background, Color foreground, Color? border}) resolvePalette(
    AppColors colors, {
    required bool isDark,
  }) => switch (widget.variant) {
    AppButtonVariant.contrast => (
      background: isDark ? AppColors.white : Colors.black,
      foreground: isDark ? Colors.black : AppColors.white,
      border: null,
    ),
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
    final palette = resolvePalette(
      context.colors,
      isDark: Theme.of(context).brightness == Brightness.dark,
    );
    final size = MediaQuery.sizeOf(context);
    final isTablet = size.width >= 600;
    final h = size.height;
    final radius = isTablet
        ? BorderRadius.circular((h * 0.024).clamp(16.0, 28.0))
        : (isSmall ? AppBorderRadius.md : AppBorderRadius.xl);
    final minHeight =
        widget.minHeight ??
        switch ((widget.size, widget.variant)) {
          (AppButtonSize.small, _) =>
            isTablet ? 48.0 : (38.h).clamp(38.0, 44.0),
          (_, AppButtonVariant.text || AppButtonVariant.dangerText) =>
            isTablet ? 54.0 : (44.h).clamp(44.0, 48.0),
          _ => isTablet ? 66.0 : (52.h).clamp(52.0, 56.0),
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
                    horizontal: (isSmall ? 14.w : 18.w).clamp(14.0, 24.0),
                  ),
                  child: AppButtonContent(
                    label: widget.label,
                    icon: widget.icon,
                    leading: widget.leading,
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
    this.leading,
    required this.isLoading,
    required this.color,
    required this.isSmall,
  });

  final String label;
  final IconData? icon;
  final Widget? leading;
  final bool isLoading;
  final Color color;
  final bool isSmall;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final isTablet = size.width >= 600;

    final btnFontSize = isTablet ? (isSmall ? 18.0 : 22.0) : null;
    final iconSize = isTablet ? (isSmall ? 22.0 : 26.0) : 20.r;

    final baseStyle = isSmall ? AppTextStyle.buttonSmall : AppTextStyle.button;
    final style =
        (btnFontSize != null
                ? baseStyle.copyWith(fontSize: btnFontSize)
                : baseStyle)
            .copyWith(color: color);
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isLoading)
          AppLoader(
            size: isTablet ? 24 : 18,
            strokeWidth: isTablet ? 2.5 : 2,
            color: color,
          )
        else if (leading != null)
          leading!
        else if (icon != null)
          Icon(icon, size: iconSize, color: color),
        if (isLoading || leading != null || icon != null)
          isTablet ? const SizedBox(width: 5.0) : 8.0.horizontalSpace,
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
