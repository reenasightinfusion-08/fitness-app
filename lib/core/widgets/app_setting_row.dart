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
    final trailingWidget =
        trailing ??
        (onTap != null
            ? Icon(Icons.chevron_right_rounded, size: 20.r, color: colors.ink3)
            : null);

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12.h),
        decoration: BoxDecoration(
          border: showDivider
              ? Border(bottom: BorderSide(color: colors.line))
              : null,
        ),
        child: Row(
          children: [
            if (leading != null) ...[leading!, 12.horizontalSpace],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyle.titleSmall.copyWith(color: titleColor),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      style: AppTextStyle.meta.copyWith(color: colors.ink2),
                    ),
                ],
              ),
            ),
            if (trailingWidget != null) ...[12.horizontalSpace, trailingWidget],
          ],
        ),
      ),
    );
  }
}
