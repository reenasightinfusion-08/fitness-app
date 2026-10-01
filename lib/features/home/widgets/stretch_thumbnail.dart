import 'package:flutter/material.dart';

import 'package:fitness_app/core/widgets/widgets.dart';
import 'package:fitness_app/features/home/models/today_plan.dart';

/// A stretch's photo in a rounded square, falling back to its drawn figure when
/// it has no photo or the photo can't load, so a list never shows a blank tile.
class StretchThumbnail extends StatelessWidget {
  const StretchThumbnail({
    super.key,
    required this.stretch,
    this.size = AppThumbSize.medium,
    this.isOnDark = false,
  });

  final StretchPreview stretch;
  final AppThumbSize size;
  final bool isOnDark;

  @override
  Widget build(BuildContext context) {
    final url = stretch.model?.thumbnailUrl;
    final figure = StretchFigure(pose: stretch.pose);
    return AppThumb(
      size: size,
      isOnDark: isOnDark,
      child: url == null || url.trim().isEmpty
          ? figure
          : Image.network(
              url,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => figure,
            ),
    );
  }
}
