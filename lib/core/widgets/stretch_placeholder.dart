import 'package:flutter/material.dart';

import 'package:fitness_app/core/theme/theme.dart';

/// Neutral stand-in for a stretch's photo or video frame while it loads or
/// when it can't be loaded. A plain block that pulses softly while [isLoading],
/// and shows a faint image icon once the media is known to be unavailable.
class StretchPlaceholder extends StatefulWidget {
  const StretchPlaceholder({
    super.key,
    this.isLoading = false,
    this.isOnDark = false,
  });

  final bool isLoading;
  final bool isOnDark;

  @override
  State<StretchPlaceholder> createState() => _StretchPlaceholderState();
}

class _StretchPlaceholderState extends State<StretchPlaceholder>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
    lowerBound: 0.55,
    value: 1,
  );

  @override
  void initState() {
    super.initState();
    if (widget.isLoading) _pulse.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant StretchPlaceholder oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isLoading == oldWidget.isLoading) return;
    if (widget.isLoading) {
      _pulse.repeat(reverse: true);
    } else {
      _pulse.value = 1;
      _pulse.stop();
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final background = widget.isOnDark
        ? colors.playerInk.withValues(alpha: 0.1)
        : colors.surface2;
    final iconColor = widget.isOnDark ? colors.playerDim : colors.ink3;

    return FadeTransition(
      opacity: _pulse,
      child: ColoredBox(
        color: background,
        child: widget.isLoading
            ? null
            : LayoutBuilder(
                builder: (context, constraints) => Center(
                  child: Icon(
                    Icons.image_outlined,
                    size: constraints.biggest.shortestSide.clamp(0, 160) * 0.4,
                    color: iconColor,
                  ),
                ),
              ),
      ),
    );
  }
}
