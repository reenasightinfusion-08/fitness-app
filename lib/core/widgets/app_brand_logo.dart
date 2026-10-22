import 'package:flutter/material.dart';

import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:fitness_app/core/theme/theme.dart';

class AppBrandLogo extends StatelessWidget {
  const AppBrandLogo({
    super.key,
    this.isLarge = false,
    this.showWordmark = true,
  });

  final bool isLarge;
  final bool showWordmark;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isTablet = MediaQuery.sizeOf(context).width >= 600;

    final markSize = isTablet
        ? (isLarge ? 96.0 : 38.0)
        : (isLarge ? 64.r : 30.r);

    final wordmarkStyle = isTablet
        ? (isLarge
            ? AppTextStyle.display(58, weight: FontWeight.w800)
                .copyWith(letterSpacing: -1.6)
            : AppTextStyle.display(32, weight: FontWeight.w800)
                .copyWith(letterSpacing: -0.9))
        : (isLarge ? AppTextStyle.hero : AppTextStyle.brandWord).copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: isLarge ? -1.2 : -0.7,
          );

    return Semantics(
      label: 'Loosen',
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CustomPaint(
            size: Size.square(markSize),
            painter: BrandMarkPainter(
              arcColor: colors.accent,
              dotColor: colors.warm,
            ),
          ),
          if (showWordmark) ...[
            (isTablet
                    ? (isLarge ? 18.0 : 12.0)
                    : (isLarge ? 12 : 8).w)
                .horizontalSpace,
            Text(
              'loosen',
              style: wordmarkStyle,
            ),
          ],
        ],
      ),
    );
  }
}

/// Arch (a body mid-stretch) with a warm head dot, drawn on a 40×40 grid.
class BrandMarkPainter extends CustomPainter {
  const BrandMarkPainter({required this.arcColor, required this.dotColor});

  final Color arcColor;
  final Color dotColor;

  @override
  void paint(Canvas canvas, Size size) {
    final unit = size.width / 40;
    final arc = Paint()
      ..color = arcColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5.5 * unit
      ..strokeCap = StrokeCap.round;
    final path = Path()
      ..moveTo(8 * unit, 32 * unit)
      ..cubicTo(
        8 * unit,
        13 * unit,
        32 * unit,
        13 * unit,
        32 * unit,
        32 * unit,
      );
    canvas.drawPath(path, arc);
    canvas.drawCircle(
      Offset(20 * unit, 8.5 * unit),
      4.5 * unit,
      Paint()..color = dotColor,
    );
  }

  @override
  bool shouldRepaint(BrandMarkPainter oldDelegate) =>
      oldDelegate.arcColor != arcColor || oldDelegate.dotColor != dotColor;
}
