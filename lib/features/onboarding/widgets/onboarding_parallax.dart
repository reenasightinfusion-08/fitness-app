import 'package:flutter/material.dart';

/// Shifts (and optionally fades) its child as the page is swiped, so layers
/// move at different speeds than the page itself.
class OnboardingParallax extends StatelessWidget {
  const OnboardingParallax({
    super.key,
    required this.controller,
    required this.index,
    required this.child,
    this.shift = -48,
    this.shouldFade = true,
  });

  final PageController controller;
  final int index;
  final Widget child;

  /// Extra horizontal travel in logical pixels at a full page of swipe.
  final double shift;
  final bool shouldFade;

  double get pageDelta {
    if (!controller.hasClients || !controller.position.haveDimensions) return 0;
    return ((controller.page ?? index.toDouble()) - index).clamp(-1.0, 1.0);
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: controller,
    child: child,
    builder: (context, child) {
      final delta = pageDelta;
      final moved = Transform.translate(
        offset: Offset(delta * shift, 0),
        child: child,
      );
      if (!shouldFade) return moved;
      return Opacity(
        opacity: (1 - delta.abs() * 1.5).clamp(0.0, 1.0),
        child: moved,
      );
    },
  );
}
