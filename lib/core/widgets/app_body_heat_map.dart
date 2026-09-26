import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:fitness_app/core/theme/theme.dart';

/// One tappable/markable spot on the body silhouette, in the prototype's
/// 0–100 view-box coordinates (`bodyMap()`'s `front`/`back` arrays).
@immutable
class BodyAreaSpot {
  const BodyAreaSpot(this.area, this.x, this.y);

  final String area;
  final double x;
  final double y;
}

/// Front-view spots, ported from the prototype's `bodyMap()`.
const List<BodyAreaSpot> frontBodySpots = [
  BodyAreaSpot('neck', 50, 20),
  BodyAreaSpot('shoulders', 38, 27),
  BodyAreaSpot('shoulders', 62, 27),
  BodyAreaSpot('chest', 50, 35),
  BodyAreaSpot('wrists', 32, 54),
  BodyAreaSpot('wrists', 68, 54),
  BodyAreaSpot('hips', 43, 52),
  BodyAreaSpot('hips', 57, 52),
  BodyAreaSpot('quads', 44, 63),
  BodyAreaSpot('quads', 56, 63),
  BodyAreaSpot('knees', 44, 72),
  BodyAreaSpot('knees', 56, 72),
];

/// Back-view spots, ported from the prototype's `bodyMap()`.
const List<BodyAreaSpot> backBodySpots = [
  BodyAreaSpot('upperback', 50, 32),
  BodyAreaSpot('lowerback', 50, 45),
  BodyAreaSpot('glutes', 44, 54),
  BodyAreaSpot('glutes', 56, 54),
  BodyAreaSpot('hamstrings', 44, 64),
  BodyAreaSpot('hamstrings', 56, 64),
  BodyAreaSpot('calves', 44, 81),
  BodyAreaSpot('calves', 56, 81),
];

/// Front + back body silhouettes with a heat dot per area, matching the
/// prototype's `bodyMap(sel,'heat',heat)`. [heat] maps an area key (from
/// `painAreaLabels`) to how often it's come up; a missing or zero key
/// draws as a dashed "not yet" dot.
class AppBodyHeatMap extends StatelessWidget {
  const AppBodyHeatMap({super.key, required this.heat});

  final Map<String, int> heat;

  @override
  Widget build(BuildContext context) {
    final maxCount = heat.values.fold(1, math.max);

    return Row(
      children: [
        Expanded(
          child: _BodyFigure(
            spots: frontBodySpots,
            heat: heat,
            maxCount: maxCount,
            label: 'Front',
          ),
        ),
        16.horizontalSpace,
        Expanded(
          child: _BodyFigure(
            spots: backBodySpots,
            heat: heat,
            maxCount: maxCount,
            label: 'Back',
          ),
        ),
      ],
    );
  }
}

class _BodyFigure extends StatelessWidget {
  const _BodyFigure({
    required this.spots,
    required this.heat,
    required this.maxCount,
    required this.label,
  });

  final List<BodyAreaSpot> spots;
  final Map<String, int> heat;
  final int maxCount;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      children: [
        AspectRatio(
          aspectRatio: 1,
          child: CustomPaint(
            painter: _BodyPainter(
              spots: spots,
              heat: heat,
              maxCount: maxCount,
              silhouetteColor: colors.surface2,
              heatColor: colors.warm,
              emptyColor: colors.ink3,
            ),
          ),
        ),
        6.verticalSpace,
        Text(
          label.toUpperCase(),
          style: AppTextStyle.eyebrow.copyWith(color: colors.ink3),
        ),
      ],
    );
  }
}

/// Draws the prototype's `silhouette()` stick figure (neutral pose,
/// thick rounded strokes) plus a heat dot per [spots] entry.
class _BodyPainter extends CustomPainter {
  const _BodyPainter({
    required this.spots,
    required this.heat,
    required this.maxCount,
    required this.silhouetteColor,
    required this.heatColor,
    required this.emptyColor,
  });

  final List<BodyAreaSpot> spots;
  final Map<String, int> heat;
  final int maxCount;
  final Color silhouetteColor;
  final Color heatColor;
  final Color emptyColor;

  // Neutral-pose joints, in the prototype's 0–100 view-box.
  static const _head = Offset(50, 12);
  static const _neck = Offset(50, 22);
  static const _hip = Offset(50, 52);
  static const _nearElbow = Offset(36, 38);
  static const _nearHand = Offset(32, 54);
  static const _farElbow = Offset(64, 38);
  static const _farHand = Offset(68, 54);
  static const _nearKnee = Offset(44, 72);
  static const _nearFoot = Offset(43, 92);
  static const _farKnee = Offset(56, 72);
  static const _farFoot = Offset(57, 92);

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 100;
    Offset at(Offset o) => Offset(o.dx * scale, o.dy * scale);

    final body = Paint()
      ..color = silhouetteColor
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    void polyline(List<Offset> points, double width) {
      final path = Path()..moveTo(at(points.first).dx, at(points.first).dy);
      for (final point in points.skip(1)) {
        path.lineTo(at(point).dx, at(point).dy);
      }
      canvas.drawPath(path, body..strokeWidth = width * scale);
    }

    polyline([_neck, _nearElbow, _nearHand], 9); // near arm
    polyline([_neck, _farElbow, _farHand], 9); // far arm
    polyline([_hip, _nearKnee, _nearFoot], 10); // near leg
    polyline([_hip, _farKnee, _farFoot], 10); // far leg
    polyline([const Offset(50, 26), const Offset(50, 50)], 17); // torso
    polyline([const Offset(42, 27), const Offset(58, 27)], 9); // shoulders
    canvas.drawCircle(at(_head), 7.5 * scale, Paint()..color = silhouetteColor);

    for (final spot in spots) {
      final count = heat[spot.area] ?? 0;
      final center = at(Offset(spot.x, spot.y));
      if (count > 0) {
        final opacity = (0.25 + 0.75 * (count / maxCount)).clamp(0.0, 1.0);
        canvas.drawCircle(
          center,
          5.5 * scale,
          Paint()..color = heatColor.withValues(alpha: opacity),
        );
      } else {
        _drawDashedCircle(
          canvas,
          center,
          4.5 * scale,
          Paint()
            ..color = emptyColor
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1 * scale,
        );
      }
    }
  }

  void _drawDashedCircle(
    Canvas canvas,
    Offset center,
    double radius,
    Paint paint,
  ) {
    const dashDegrees = 40.0, gapDegrees = 40.0;
    var degrees = 0.0;
    while (degrees < 360) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        degrees * math.pi / 180,
        dashDegrees * math.pi / 180,
        false,
        paint,
      );
      degrees += dashDegrees + gapDegrees;
    }
  }

  @override
  bool shouldRepaint(covariant _BodyPainter oldDelegate) =>
      oldDelegate.heat != heat ||
      oldDelegate.maxCount != maxCount ||
      oldDelegate.silhouetteColor != silhouetteColor ||
      oldDelegate.heatColor != heatColor ||
      oldDelegate.emptyColor != emptyColor;
}
