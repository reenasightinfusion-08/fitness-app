import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import 'package:fitness_app/core/theme/theme.dart';
import 'package:fitness_app/core/widgets/widgets.dart';
import 'package:fitness_app/services/video_background_service.dart';

class StretchMediaPlayer extends StatefulWidget {
  const StretchMediaPlayer({
    super.key,
    this.videoUrl,
    this.thumbnailUrl,
    this.holdSeconds = 30,
    required this.pose,
    this.playing = true,
    this.showVideo = true,
  });

  final String? videoUrl;
  final String? thumbnailUrl;

  /// The stretch's default hold time; picks which video frame is shown.
  final int holdSeconds;
  final StretchPose pose;

  /// False while the session is paused: the video freezes on its current
  /// frame and resumes from there.
  final bool playing;

  /// False during the get-into-position and switch-sides beats: the
  /// thumbnail is shown while the video stays preloaded for the hold.
  final bool showVideo;

  @override
  State<StretchMediaPlayer> createState() => _StretchMediaPlayerState();
}

class _StretchMediaPlayerState extends State<StretchMediaPlayer> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _hasError = false;
  VideoBackground? _background;

  @override
  void initState() {
    super.initState();
    _background = VideoBackgroundService.getCached(widget.videoUrl);
    _initVideo();
  }

  @override
  void didUpdateWidget(covariant StretchMediaPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.videoUrl != widget.videoUrl) {
      _disposeVideo();
      _background = VideoBackgroundService.getCached(widget.videoUrl);
      _initVideo();
      return;
    }
    if (oldWidget.playing != widget.playing ||
        oldWidget.showVideo != widget.showVideo) {
      _syncPlayback();
    }
  }

  void _syncPlayback() {
    final controller = _controller;
    if (controller == null || !_isInitialized) return;
    widget.playing && widget.showVideo ? controller.play() : controller.pause();
  }

  Future<void> _initVideo() async {
    final url = widget.videoUrl;
    if (url == null || url.trim().isEmpty) return;

    final controller = VideoPlayerController.networkUrl(Uri.parse(url));
    _controller = controller;
    try {
      await controller.initialize();
      // A newer stretch (or dispose) replaced this controller mid-load.
      if (!mounted || _controller != controller) {
        await controller.dispose();
        return;
      }
      await controller.setLooping(true);
      await controller.setVolume(0);

      // Detect the vignette background profile of the video.
      // Falls back to brand color after 3 seconds so video playback never hangs.
      final background = await VideoBackgroundService.detect(url).timeout(
        const Duration(seconds: 3),
        onTimeout: () => VideoBackground.fallback,
      );
      if (!mounted || _controller != controller) {
        await controller.dispose();
        return;
      }
      setState(() {
        _background = background ?? VideoBackground.fallback;
        _isInitialized = true;
      });
      _syncPlayback();
    } catch (_) {
      if (mounted && _controller == controller) {
        setState(() => _hasError = true);
      }
    }
  }

  void _disposeVideo() {
    _controller?.dispose();
    _controller = null;
    _isInitialized = false;
    _hasError = false;
    _background = null;
  }

  @override
  void dispose() {
    _disposeVideo();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final controller = _controller;

    if (widget.showVideo && _isInitialized && controller != null && !_hasError) {
      final background = _background ?? VideoBackground.fallback;
      final videoSize = controller.value.size;

      return Stack(
        fit: StackFit.expand,
        children: [
          // 1. Precise background painter that extends the video's edge vignette
          // horizontally/vertically into letterbox and pillarbox bars.
          CustomPaint(
            painter: VideoBackgroundPainter(
              background: background,
              videoSize: videoSize,
            ),
          ),
          // 2. Centered video with soft edge feathering so there is zero hard seam.
          SizedBox.expand(
            child: FittedBox(
              fit: BoxFit.contain,
              child: SizedBox(
                width: videoSize.width,
                height: videoSize.height,
                child: _EdgeFeatherMask(
                  child: VideoPlayer(controller),
                ),
              ),
            ),
          ),
        ],
      );
    }

    final thumb = widget.thumbnailUrl;
    if (thumb != null && thumb.trim().isNotEmpty) {
      final background = _background;
      return Stack(
        fit: StackFit.expand,
        children: [
          if (background != null)
            CustomPaint(
              painter: VideoBackgroundPainter(
                background: background,
                videoSize: controller?.value.size ?? const Size(16, 9),
              ),
            ),
          StretchVideoFrame(
            videoUrl: widget.videoUrl,
            holdSeconds: widget.holdSeconds,
            fit: BoxFit.contain,
            fallback: Image.network(
              thumb,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) =>
                  _buildStickFigure(colors),
            ),
          ),
        ],
      );
    }

    return _buildStickFigure(colors);
  }

  Widget _buildStickFigure(AppColors colors) {
    return AnimatedStretchFigure(
      pose: widget.pose,
      nearColor: colors.playerInk,
      farColor: colors.playerDim,
      groundColor: colors.playerInk.withValues(alpha: 0.14),
    );
  }
}

/// Paints the container background behind and around the video.
///
/// In letterbox (bars on top/bottom):
/// - The top bar is filled with a horizontal gradient matching the video's top edge
///   vignette ([topLeft, topCenter, topRight]).
/// - The bottom bar is filled with a horizontal gradient matching the video's bottom
///   edge vignette ([bottomLeft, bottomCenter, bottomRight]).
/// - Behind the video: a smooth vertical transition connects top and bottom edges.
///
/// In pillarbox (bars on left/right):
/// - The left bar is filled with a vertical gradient matching the left edge vignette.
/// - The right bar is filled with a vertical gradient matching the right edge vignette.
/// - Behind the video: a smooth horizontal transition connects left and right edges.
class VideoBackgroundPainter extends CustomPainter {
  const VideoBackgroundPainter({
    required this.background,
    required this.videoSize,
  });

  final VideoBackground background;
  final Size videoSize;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final bg = background;
    final fitted = applyBoxFit(BoxFit.contain, videoSize, size);
    final videoRect = Alignment.center.inscribe(
      fitted.destination,
      Offset.zero & size,
    );

    final paint = Paint()..isAntiAlias = true;

    final isLetterbox = videoRect.top > 0.5 || videoRect.bottom < size.height - 0.5;
    final isPillarbox = videoRect.left > 0.5 || videoRect.right < size.width - 0.5;

    if (isLetterbox) {
      // Top bar: Horizontal gradient matching the video's top edge vignette
      if (videoRect.top > 0) {
        final topBar = Rect.fromLTRB(0, 0, size.width, videoRect.top);
        paint.shader = ui.Gradient.linear(
          Offset.zero,
          Offset(size.width, 0),
          [bg.topLeft, bg.topCenter, bg.topRight],
          const [0.0, 0.5, 1.0],
        );
        canvas.drawRect(topBar, paint);
      }

      // Bottom bar: Horizontal gradient matching the video's bottom edge vignette
      if (videoRect.bottom < size.height) {
        final bottomBar = Rect.fromLTRB(0, videoRect.bottom, size.width, size.height);
        paint.shader = ui.Gradient.linear(
          Offset(0, videoRect.bottom),
          Offset(size.width, videoRect.bottom),
          [bg.bottomLeft, bg.bottomCenter, bg.bottomRight],
          const [0.0, 0.5, 1.0],
        );
        canvas.drawRect(bottomBar, paint);
      }

      // Behind the video: Smooth vertical transition between top and bottom edges
      final videoArea = Rect.fromLTRB(0, videoRect.top, size.width, videoRect.bottom);
      paint.shader = ui.Gradient.linear(
        Offset(0, videoRect.top),
        Offset(0, videoRect.bottom),
        [bg.topCenter, bg.bottomCenter],
      );
      canvas.drawRect(videoArea, paint);
    } else if (isPillarbox) {
      // Left bar: Vertical gradient matching the video's left edge vignette
      if (videoRect.left > 0) {
        final leftBar = Rect.fromLTRB(0, 0, videoRect.left, size.height);
        paint.shader = ui.Gradient.linear(
          Offset.zero,
          Offset(0, size.height),
          [bg.topLeft, bg.leftCenter, bg.bottomLeft],
          const [0.0, 0.5, 1.0],
        );
        canvas.drawRect(leftBar, paint);
      }

      // Right bar: Vertical gradient matching the video's right edge vignette
      if (videoRect.right < size.width) {
        final rightBar = Rect.fromLTRB(videoRect.right, 0, size.width, size.height);
        paint.shader = ui.Gradient.linear(
          Offset(videoRect.right, 0),
          Offset(videoRect.right, size.height),
          [bg.topRight, bg.rightCenter, bg.bottomRight],
          const [0.0, 0.5, 1.0],
        );
        canvas.drawRect(rightBar, paint);
      }

      // Behind the video: Smooth horizontal transition between left and right edges
      final videoArea = Rect.fromLTRB(videoRect.left, 0, videoRect.right, size.height);
      paint.shader = ui.Gradient.linear(
        Offset(videoRect.left, 0),
        Offset(videoRect.right, 0),
        [bg.leftCenter, bg.rightCenter],
      );
      canvas.drawRect(videoArea, paint);
    } else {
      // Container matches video aspect ratio exactly: fallback fill behind video
      paint.shader = ui.Gradient.linear(
        Offset.zero,
        Offset(0, size.height),
        [bg.topCenter, bg.bottomCenter],
      );
      canvas.drawRect(Offset.zero & size, paint);
    }
  }

  @override
  bool shouldRepaint(covariant VideoBackgroundPainter oldDelegate) {
    return oldDelegate.background != background ||
        oldDelegate.videoSize != videoSize;
  }
}

/// Smoothly feathers the outer perimeter of the video into the container background.
///
/// Blends from alpha 0.0 at the video boundary to alpha 1.0 inward over ~12-16
/// logical pixels. This eliminates any step discontinuity at the seam and
/// renders any minor color-space (YUV->RGB) or subpixel alignment difference
/// completely imperceptible.
class _EdgeFeatherMask extends StatelessWidget {
  const _EdgeFeatherMask({required this.child});

  final Widget child;

  static const double featherHorizontal = 0.035;
  static const double featherVertical = 0.05;

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      blendMode: BlendMode.dstIn,
      shaderCallback: (bounds) {
        final fh = (bounds.height * featherVertical).clamp(6.0, 36.0);
        final topStop = bounds.height > 0 ? (fh / bounds.height) : 0.0;
        final botStop = (1.0 - topStop).clamp(topStop, 1.0);
        return LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: const [
            Colors.transparent,
            Colors.white,
            Colors.white,
            Colors.transparent,
          ],
          stops: [0.0, topStop, botStop, 1.0],
        ).createShader(bounds);
      },
      child: ShaderMask(
        blendMode: BlendMode.dstIn,
        shaderCallback: (bounds) {
          final fw = (bounds.width * featherHorizontal).clamp(6.0, 36.0);
          final leftStop = bounds.width > 0 ? (fw / bounds.width) : 0.0;
          final rightStop = (1.0 - leftStop).clamp(leftStop, 1.0);
          return LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: const [
              Colors.transparent,
              Colors.white,
              Colors.white,
              Colors.transparent,
            ],
            stops: [0.0, leftStop, rightStop, 1.0],
          ).createShader(bounds);
        },
        child: child,
      ),
    );
  }
}
