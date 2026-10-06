import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

/// The measured edge colors of a video, capturing the AI generator's vignette
/// so the letterbox/pillarbox container can match the video's border perfectly.
class VideoBackground {
  const VideoBackground({
    required this.topLeft,
    required this.topCenter,
    required this.topRight,
    required this.bottomLeft,
    required this.bottomCenter,
    required this.bottomRight,
    required this.leftCenter,
    required this.rightCenter,
  });

  final Color topLeft;
  final Color topCenter;
  final Color topRight;
  final Color bottomLeft;
  final Color bottomCenter;
  final Color bottomRight;
  final Color leftCenter;
  final Color rightCenter;

  /// Brand fallback color (#EFEBE5).
  static const VideoBackground fallback = VideoBackground(
    topLeft: Color(0xFFEFEBE5),
    topCenter: Color(0xFFEFEBE5),
    topRight: Color(0xFFEFEBE5),
    bottomLeft: Color(0xFFEFEBE5),
    bottomCenter: Color(0xFFEFEBE5),
    bottomRight: Color(0xFFEFEBE5),
    leftCenter: Color(0xFFEFEBE5),
    rightCenter: Color(0xFFEFEBE5),
  );
}

/// Reads a video's background by sampling its perimeter on the first frame.
///
/// Uses an averaged 3x3 pixel block at 8 perimeter points to capture the
/// vignette while ignoring single-pixel compression/quantization noise.
class VideoBackgroundService {
  static final Map<String, VideoBackground?> _cache = {};

  /// Instant synchronous getter from cache (0ms delay).
  static VideoBackground? getCached(String? url) =>
      url == null ? null : _cache[url];

  /// Preloads background colors for a list of video URLs in the background.
  static void preloadUrls(Iterable<String?> urls) {
    for (final url in urls) {
      if (url != null && url.trim().isNotEmpty && !_cache.containsKey(url)) {
        detect(url);
      }
    }
  }

  /// Returns null when the frame can't be read; callers fall back to [VideoBackground.fallback].
  static Future<VideoBackground?> detect(String url) async {
    if (_cache.containsKey(url)) return _cache[url];
    VideoBackground? result;
    try {
      final bytes = await VideoThumbnail.thumbnailData(
        video: url,
        imageFormat: ImageFormat.PNG,
        timeMs: 0,
        maxWidth: 160,
        quality: 90,
      );
      if (bytes != null) {
        final codec = await ui.instantiateImageCodec(bytes);
        final frameInfo = await codec.getNextFrame();
        final image = frameInfo.image;
        try {
          final byteData = await image.toByteData(
            format: ui.ImageByteFormat.rawRgba,
          );
          if (byteData != null) {
            final w = image.width;
            final h = image.height;

            // Sample an averaged 3x3 block around (cx, cy) to filter out
            // single-pixel video compression noise.
            Color sample(int cx, int cy) {
              int r = 0, g = 0, b = 0, count = 0;
              for (int dy = -1; dy <= 1; dy++) {
                for (int dx = -1; dx <= 1; dx++) {
                  final x = (cx + dx).clamp(0, w - 1);
                  final y = (cy + dy).clamp(0, h - 1);
                  final offset = (y * w + x) * 4;
                  r += byteData.getUint8(offset);
                  g += byteData.getUint8(offset + 1);
                  b += byteData.getUint8(offset + 2);
                  count++;
                }
              }
              return Color.fromARGB(255, r ~/ count, g ~/ count, b ~/ count);
            }

            // Inset by ~4% of dimensions to bypass H.264 macroblock border padding.
            final insetX = (w * 0.04).round().clamp(2, 8);
            final insetY = (h * 0.04).round().clamp(2, 6);
            final midX = w ~/ 2;
            final midY = h ~/ 2;

            result = VideoBackground(
              topLeft: sample(insetX, insetY),
              topCenter: sample(midX, insetY),
              topRight: sample(w - 1 - insetX, insetY),
              bottomLeft: sample(insetX, h - 1 - insetY),
              bottomCenter: sample(midX, h - 1 - insetY),
              bottomRight: sample(w - 1 - insetX, h - 1 - insetY),
              leftCenter: sample(insetX, midY),
              rightCenter: sample(w - 1 - insetX, midY),
            );
          }
        } finally {
          image.dispose();
        }
      }
    } catch (_) {
      result = null;
    }
    _cache[url] = result;
    return result;
  }
}
