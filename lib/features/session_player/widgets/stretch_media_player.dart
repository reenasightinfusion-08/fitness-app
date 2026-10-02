import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import 'package:fitness_app/core/theme/theme.dart';
import 'package:fitness_app/core/widgets/widgets.dart';

class StretchMediaPlayer extends StatefulWidget {
  const StretchMediaPlayer({
    super.key,
    this.videoUrl,
    this.thumbnailUrl,
    required this.pose,
    this.playing = true,
    this.showVideo = true,
  });

  final String? videoUrl;
  final String? thumbnailUrl;
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

  @override
  void initState() {
    super.initState();
    _initVideo();
  }

  @override
  void didUpdateWidget(covariant StretchMediaPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.videoUrl != widget.videoUrl) {
      _disposeVideo();
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
      setState(() => _isInitialized = true);
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
      return SizedBox.expand(
        child: FittedBox(
          fit: BoxFit.cover,
          clipBehavior: Clip.hardEdge,
          child: SizedBox(
            width: controller.value.size.width,
            height: controller.value.size.height,
            child: VideoPlayer(controller),
          ),
        ),
      );
    }

    final thumb = widget.thumbnailUrl;
    if (thumb != null && thumb.trim().isNotEmpty) {
      return Image.network(
        thumb,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildStickFigure(colors),
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
