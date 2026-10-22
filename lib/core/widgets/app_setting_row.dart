import 'package:flutter/material.dart';

import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:fitness_app/core/theme/theme.dart';

/// Row inside a list card: settings toggles, profile links, stretch rows.
/// Shows a chevron automatically when tappable and no [trailing] is given.
class AppSettingRow extends StatelessWidget {
  const AppSettingRow({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.onTap,
    this.showDivider = true,
    this.titleColor,
  });

  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool showDivider;
  final Color? titleColor;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final size = MediaQuery.sizeOf(context);
    final isTablet = size.width >= 600;
    final titleFontSize = isTablet ? 15.0 : null;
    final subFontSize = isTablet ? 13.0 : null;
    final padV = isTablet ? 12.0 : 12.h;
    final chevronSize = isTablet ? 20.0 : 20.r;

    final trailingWidget =
        trailing ??
        (onTap != null
            ? Icon(
                Icons.chevron_right_rounded,
                size: chevronSize,
                color: colors.ink3,
              )
            : null);

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: padV),
        decoration: BoxDecoration(
          border: showDivider
              ? Border(bottom: BorderSide(color: colors.line))
              : null,
        ),
        child: Row(
          children: [
            if (leading != null) ...[
              leading!,
              (isTablet ? 16.0 : 12.0).horizontalSpace,
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyle.titleSmall.copyWith(
                      color: titleColor,
                      fontSize: titleFontSize,
                    ),
                  ),
                  if (subtitle != null) ...[
                    if (isTablet) const SizedBox(height: 4.0),
                    Text(
                      subtitle!,
                      style: AppTextStyle.meta.copyWith(
                        color: colors.ink2,
                        fontSize: subFontSize,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (trailingWidget != null) ...[
              (isTablet ? 16.0 : 12.0).horizontalSpace,
              trailingWidget,
            ],
          ],
        ),
      ),
    );
  }
}
