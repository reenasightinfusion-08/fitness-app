import 'package:flutter/material.dart';

/// A simple, static skeleton placeholder widget (no gradient animation or moving highlights).
class AppShimmer extends StatelessWidget {
  const AppShimmer({
    super.key,
    this.width,
    this.height,
    this.borderRadius = 12.0,
    this.shape = BoxShape.rectangle,
    this.color = const Color(0xFFE2E7E4),
    this.child,
  });

  /// Factory constructor for circular static placeholders (e.g., avatars).
  factory AppShimmer.circle({
    Key? key,
    required double size,
    Color color = const Color(0xFFE2E7E4),
  }) {
    return AppShimmer(
      key: key,
      width: size,
      height: size,
      shape: BoxShape.circle,
      color: color,
    );
  }

  /// Factory constructor for rounded rectangular static placeholder blocks/cards.
  factory AppShimmer.box({
    Key? key,
    double? width,
    double? height,
    double borderRadius = 12.0,
    Color color = const Color(0xFFE2E7E4),
  }) {
    return AppShimmer(
      key: key,
      width: width,
      height: height,
      borderRadius: borderRadius,
      color: color,
    );
  }

  final double? width;
  final double? height;
  final double borderRadius;
  final BoxShape shape;
  final Color color;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        shape: shape,
        borderRadius: shape == BoxShape.rectangle
            ? BorderRadius.circular(borderRadius)
            : null,
      ),
      child: child,
    );
  }
}
