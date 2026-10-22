// ignore_for_file: deprecated_member_use, avoid_web_libraries_in_flutter

import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;
import 'dart:typed_data';

/// Extracts a JPEG still frame from a video URL on the web platform using an
/// off-screen HTML5 video and canvas element.
Future<Uint8List?> grabWebFrame(String url, int timeMs) async {
  try {
    final video = html.VideoElement()
      ..crossOrigin = 'anonymous'
      ..preload = 'auto'
      ..muted = true
      ..autoplay = false
      ..setAttribute('playsinline', 'true')
      ..setAttribute('webkit-playsinline', 'true')
      ..src = url;

    // Explicitly call load() so unattached DOM video starts fetching on web
    video.load();

    final completer = Completer<Uint8List?>();

    void captureFrame() {
      if (completer.isCompleted) return;
      try {
        final w = video.videoWidth > 0 ? video.videoWidth : 480;
        final h = video.videoHeight > 0 ? video.videoHeight : 270;
        final canvas = html.CanvasElement(width: w, height: h);
        final ctx = canvas.context2D;
        ctx.drawImage(video, 0, 0);

        final dataUrl = canvas.toDataUrl('image/jpeg', 0.85);
        final commaIdx = dataUrl.indexOf(',');
        if (commaIdx != -1) {
          final base64String = dataUrl.substring(commaIdx + 1);
          final bytes = base64Decode(base64String);
          if (bytes.isNotEmpty) {
            completer.complete(bytes);
            return;
          }
        }
      } catch (_) {
        // Tainted canvas or canvas draw issue
      }
      if (!completer.isCompleted) completer.complete(null);
    }

    final targetSeconds = (timeMs / 1000.0);

    video.onLoadedData.first
        .then((_) {
          if (targetSeconds <= 0.2) {
            captureFrame();
          } else {
            final duration = video.duration;
            final seekTo = duration.isFinite && duration > 0
                ? targetSeconds.clamp(0.1, duration.toDouble() - 0.1)
                : targetSeconds;
            video.currentTime = seekTo;

            video.onSeeked.first.then((_) => captureFrame()).catchError((_) {
              captureFrame();
            });

            // If seek takes longer than 1.5s, capture the buffered front frame
            Timer(const Duration(milliseconds: 1500), () {
              if (!completer.isCompleted) captureFrame();
            });
          }
        })
        .catchError((_) {
          video.onCanPlay.first.then((_) => captureFrame()).catchError((_) {
            if (!completer.isCompleted) completer.complete(null);
          });
        });

    video.onError.first.then((_) {
      if (!completer.isCompleted) completer.complete(null);
    });

    // 4-second safety timeout
    Timer(const Duration(seconds: 4), () {
      if (!completer.isCompleted) completer.complete(null);
    });

    final result = await completer.future;
    video.src = '';
    return result;
  } catch (_) {
    return null;
  }
}
