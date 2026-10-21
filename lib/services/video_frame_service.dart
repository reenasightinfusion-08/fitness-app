import 'dart:async';
import 'dart:collection';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

/// Grabs a still frame from the middle of a stretch video so a separate
/// thumbnail image doesn't have to be stored.
///
/// A frame is extracted once per video, kept in memory and on disk, so later
/// launches read it from a local file instead of re-fetching the video.
/// Extraction runs a few at a time so a long list doesn't flood the network.
class VideoFrameService {
  static const int maxConcurrent = 3;
  static const int width = 720;
  static const Duration _retryAfter = Duration(seconds: 30);

  static final Map<String, Future<Uint8List?>> _cache = {};
  static final Queue<String> _order = Queue();
  static final Map<String, Completer<void>> _waiting = {};
  static int _running = 0;

  /// Half of the hold time, in ms.
  static int midpointMs(int holdSeconds) => holdSeconds * 500;

  /// Null when the frame can't be read; callers fall back to the drawn figure.
  static Future<Uint8List?> frameAt(String url, {required int timeMs}) {
    final key = '$url|$timeMs';
    final cached = _cache[key];
    if (cached != null) return cached;
    final future = _load(key, url, timeMs);
    _cache[key] = future;
    future.then((bytes) {
      // Keep the failed future for a while so widgets that rebuild don't
      // restart the extraction (and flash their fallback) on every frame.
      if (bytes == null) {
        Timer(_retryAfter, () => _cache.remove(key));
      }
    });
    return future;
  }

  /// Warms the cache so a screen finds its frame already there. With
  /// [urgent], a frame still waiting in the queue jumps to the front.
  static void prefetch(String? url, int holdSeconds, {bool urgent = false}) {
    if (url == null || url.trim().isEmpty) return;
    final timeMs = midpointMs(holdSeconds);
    unawaited(frameAt(url, timeMs: timeMs));
    if (urgent) _promote('$url|$timeMs');
  }

  static void _promote(String key) {
    if (_order.remove(key)) _order.addFirst(key);
  }

  static Future<Uint8List?> _load(String key, String url, int timeMs) async {
    if (kIsWeb) return null;
    final file = File('${Directory.systemTemp.path}/frame_${_hash(key)}.jpg');
    try {
      if (await file.exists()) {
        final bytes = await file.readAsBytes();
        if (bytes.isNotEmpty) return bytes;
      }
    } catch (_) {}

    await _acquire(key);
    try {
      // iOS (AVAssetImageGenerator) fails when the requested time is past the
      // end of a short clip, where Android clamps to the last frame. Fall back
      // to the first frame so every video still gets a still.
      for (final at in {timeMs, 0}) {
        final bytes = await _grab(url, at);
        if (bytes != null && bytes.isNotEmpty) {
          unawaited(file.writeAsBytes(bytes).then((_) {}, onError: (_) {}));
          return bytes;
        }
      }
      return null;
    } finally {
      _release();
    }
  }

  static Future<Uint8List?> _grab(String url, int timeMs) async {
    try {
      return await VideoThumbnail.thumbnailData(
        video: url,
        imageFormat: ImageFormat.JPEG,
        timeMs: timeMs,
        maxWidth: width,
        quality: 85,
      );
    } catch (_) {
      return null;
    }
  }

  static Future<void> _acquire(String key) async {
    if (_running < maxConcurrent) {
      _running++;
      return;
    }
    final waiter = Completer<void>();
    _waiting[key] = waiter;
    _order.addLast(key);
    await waiter.future;
  }

  static void _release() {
    if (_order.isEmpty) {
      _running--;
    } else {
      _waiting.remove(_order.removeFirst())?.complete();
    }
  }

  /// 32-bit FNV-1a, compatible with both native 64-bit Dart and JavaScript.
  static String _hash(String input) {
    var hash = 0x811c9dc5;
    for (final unit in input.codeUnits) {
      hash ^= unit;
      hash = (hash * 0x01000193) & 0xFFFFFFFF;
    }
    return hash.toUnsigned(32).toRadixString(16);
  }
}
