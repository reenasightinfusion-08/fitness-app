import 'package:flutter/material.dart';

import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:fitness_app/core/theme/theme.dart';

enum AppThumbSize { small, medium, large, extraLarge }

/// Rounded square holding a stretch illustration or photo.
/// Falls back to a stretching icon when neither is provided.
class AppThumb extends StatelessWidget {
  const AppThumb({
    super.key,
    this.image,
    this.child,
    this.size = AppThumbSize.medium,
    this.isOnDark = false,
  });

  final ImageProvider? image;
  final Widget? child;
  final AppThumbSize size;
  final bool isOnDark;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final (dimension, radius) = switch (size) {
      AppThumbSize.small => (42.r, 11.r),
      AppThumbSize.medium => (52.r, 14.r),
      AppThumbSize.large => (64.r, 16.r),
      AppThumbSize.extraLarge => (72.r, 16.r),
    };

    return Container(
      width: dimension,
      height: dimension,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: isOnDark
            ? colors.playerInk.withValues(alpha: 0.1)
            : colors.surface2,
        borderRadius: BorderRadius.circular(radius),
        image: image == null
            ? null
            : DecorationImage(image: image!, fit: BoxFit.cover),
      ),
      child: image != null
          ? null
          : child ??
                Icon(
                  Icons.self_improvement_rounded,
                  size: dimension * 0.55,
                  color: isOnDark ? colors.playerInk : colors.ink2,
                ),
    );
  }
}
