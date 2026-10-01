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
  });

  final String? videoUrl;
  final String? thumbnailUrl;
  final StretchPose pose;

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
    if (oldWidget.videoUrl != widget.videoUrl || oldWidget.pose != widget.pose) {
      _disposeVideo();
      _initVideo();
    }
  }

  Future<void> _initVideo() async {
    final url = widget.videoUrl;
    if (url == null || url.trim().isEmpty) return;

    try {
      final controller = VideoPlayerController.networkUrl(Uri.parse(url));
      _controller = controller;
      await controller.initialize();
      if (!mounted) return;

      controller.setLooping(false);
      controller.setVolume(0);
      controller.play();

      setState(() {
        _isInitialized = true;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _hasError = true;
        });
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

    if (_isInitialized && _controller != null && !_hasError) {
      return SizedBox.expand(
        child: FittedBox(
          fit: BoxFit.cover,
          clipBehavior: Clip.hardEdge,
          child: SizedBox(
            width: _controller!.value.size.width,
            height: _controller!.value.size.height,
            child: VideoPlayer(_controller!),
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
