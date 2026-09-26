import 'package:flutter/material.dart';

import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:fitness_app/core/theme/theme.dart';

enum AppCardVariant {
  /// Standard padded surface.
  surface,

  /// Horizontal padding only — for stacks of [AppSettingRow]s.
  list,
}

class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.variant = AppCardVariant.surface,
    this.onTap,
    this.padding,
    this.borderRadius,
  });

  final Widget child;
  final AppCardVariant variant;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final radius = borderRadius ?? AppBorderRadius.card;
    final resolvedPadding =
        padding ??
        switch (variant) {
          AppCardVariant.surface => AppInsets.card,
          AppCardVariant.list => EdgeInsets.symmetric(
            horizontal: 16.w,
            vertical: 4.h,
          ),
        };

    return Material(
      color: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: BorderSide(color: colors.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(padding: resolvedPadding, child: child),
      ),
    );
  }
}
