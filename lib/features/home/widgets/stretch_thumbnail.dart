import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'package:fitness_app/core/widgets/widgets.dart';
import 'package:fitness_app/features/home/models/today_plan.dart';
import 'package:fitness_app/services/video_frame_service.dart';

/// A stretch tile in a rounded square showing a frame from the middle of its
/// video. Falls back to the API photo, then the drawn figure, so a list never
/// shows a blank tile.
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
    final model = stretch.model;
    final url = model?.thumbnailUrl;
    final videoUrl = model?.videoUrl;
    final figure = StretchFigure(pose: stretch.pose);
    final hasPhoto = url != null && url.trim().isNotEmpty;
    final hasVideo = videoUrl != null && videoUrl.trim().isNotEmpty;

    final Widget photo = hasPhoto
        ? Image.network(
            url,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => figure,
          )
        : figure;

    final Widget child = !hasVideo
        ? photo
        : FutureBuilder<Uint8List?>(
            future: VideoFrameService.frameAt(
              videoUrl,
              timeMs: VideoFrameService.midpointMs(model!.defaultHoldSeconds),
            ),
            builder: (context, snapshot) {
              final bytes = snapshot.data;
              if (bytes != null) {
                return Image.memory(
                  bytes,
                  fit: BoxFit.cover,
                  gaplessPlayback: true,
                );
              }
              return snapshot.connectionState == ConnectionState.done
                  ? photo
                  : figure;
            },
          );
    return AppThumb(size: size, isOnDark: isOnDark, child: child);
  }
}
