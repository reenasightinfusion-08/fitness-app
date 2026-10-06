import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'package:fitness_app/services/video_frame_service.dart';

/// A still frame from the middle of a stretch video, so no separate thumbnail
/// image is needed. Shows [fallback] when there is no video or the frame can't
/// be read, and nothing while the frame loads.
class StretchVideoFrame extends StatelessWidget {
  const StretchVideoFrame({
    super.key,
    required this.videoUrl,
    required this.fallback,
    this.holdSeconds = 30,
    this.fit = BoxFit.cover,
  });

  final String? videoUrl;
  final int holdSeconds;
  final BoxFit fit;
  final Widget fallback;

  @override
  Widget build(BuildContext context) {
    final url = videoUrl;
    if (url == null || url.trim().isEmpty) return fallback;
    return FutureBuilder<Uint8List?>(
      future: VideoFrameService.frameAt(
        url,
        timeMs: VideoFrameService.midpointMs(holdSeconds),
      ),
      builder: (context, snapshot) {
        final bytes = snapshot.data;
        final Widget child = bytes != null
            ? Image.memory(
                bytes,
                key: const ValueKey('frame'),
                fit: fit,
                width: double.infinity,
                height: double.infinity,
                filterQuality: FilterQuality.high,
                gaplessPlayback: true,
              )
            : snapshot.connectionState == ConnectionState.done
            ? fallback
            : const SizedBox.expand(key: ValueKey('loading'));
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: child,
        );
      },
    );
  }
}
