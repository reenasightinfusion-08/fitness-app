import 'package:flutter/material.dart';

import 'package:fitness_app/core/theme/theme.dart';

/// A single stick-figure pose, ported 1:1 from the prototype's `POSE_DEF`
/// table (`fig(pose)` / `limbs(j, pose)` in the HTML mock).
///
/// [joints] holds 11 (x, y) pairs on a 0–100 grid, in this order: head,
/// neck, hip, nearElbow, nearHand, farElbow, farHand, nearKnee, nearFoot,
/// farKnee, farFoot — followed by an optional 23rd value, how far the
/// torso bows away from a straight line (the prototype's `arch`).
@immutable
class StretchPose {
  const StretchPose(this.joints);

  final List<double> joints;

  double get archAmount => joints.length > 22 ? joints[22] : 0;

  Offset jointAt(int index) => Offset(joints[index * 2], joints[index * 2 + 1]);

  /// Blends this pose toward [other] by [t] (0 = this pose, 1 = [other]),
  /// joint by joint — mirrors the prototype's `lerpPose()`. Used to
  /// animate the figure moving from a neutral stance into a stretch.
  StretchPose lerp(StretchPose other, double t) {
    final a = _padded(joints);
    final b = _padded(other.joints);
    return StretchPose([
      for (var i = 0; i < a.length; i++) a[i] + (b[i] - a[i]) * t,
    ]);
  }

  static List<double> _padded(List<double> j) =>
      j.length >= 23 ? j : [...j, 0];

  /// The lightly offset pose the figure breathes toward while holding —
  /// head, neck and both arms lift by a hair; hips and legs stay put.
  /// Mirrors the prototype's default `POSES[k].b` (every pose without an
  /// authored second frame gets this same subtle lift).
  StretchPose get defaultBreathPartner {
    final j = _padded(joints).toList();
    for (final i in const [1, 3, 7, 9, 11, 13]) {
      j[i] -= 1.3;
    }
    return StretchPose(j);
  }
}

/// Every pose the prototype defines, ported verbatim so the illustration
/// is pixel-identical to the mock rather than an approximation.
class StretchPoses {
  const StretchPoses._();

  static const neutral = StretchPose([
    50, 12, 50, 22, 50, 52, 36, 38, 32, 54, 64, 38, 68, 54, 44, 72, 43, 92, 56,
    72, 57, 92,
  ]);
  static const reach = StretchPose([
    50, 17, 50, 27, 50, 55, 45, 16, 43, 6, 55, 16, 57, 6, 47, 73, 46, 91, 53,
    73, 54, 91,
  ]);
  static const sidebend = StretchPose([
    58, 20, 55, 29, 50, 56, 46, 16, 60, 8, 60, 40, 60, 52, 47, 74, 46, 91, 53,
    74, 54, 91, 3,
  ]);
  static const necktilt = StretchPose([
    43, 19, 50, 27, 50, 55, 38, 24, 41, 14, 57, 40, 58, 54, 47, 73, 46, 91, 53,
    73, 54, 91,
  ]);
  static const cross = StretchPose([
    50, 17, 50, 27, 50, 55, 60, 33, 70, 33, 60, 43, 61, 34, 47, 73, 46, 91, 53,
    73, 54, 91,
  ]);
  static const wallchest = StretchPose([
    44, 17, 46, 27, 48, 55, 64, 28, 79, 26, 44, 42, 44, 54, 46, 73, 42, 91, 50,
    73, 52, 91,
  ]);
  static const fold = StretchPose([
    60, 83, 58, 73, 44, 50, 55, 82, 54, 90, 57, 82, 57, 90, 45, 70, 46, 91, 43,
    70, 42, 91, 4,
  ]);
  static const quad = StretchPose([
    52, 17, 51, 27, 50, 55, 60, 36, 68, 32, 44, 44, 37, 60, 51, 73, 51, 91, 50,
    74, 36, 62,
  ]);
  static const calf = StretchPose([
    65, 20, 61, 29, 50, 55, 70, 32, 81, 30, 71, 34, 81, 33, 62, 73, 62, 91, 40,
    73, 30, 91,
  ]);
  static const wrist = StretchPose([
    50, 17, 50, 27, 50, 55, 62, 30, 73, 30, 58, 38, 72, 32, 50, 73, 50, 91, 49,
    73, 48, 91,
  ]);
  static const chairtwist = StretchPose([
    53, 22, 50, 32, 50, 60, 50, 46, 60, 62, 64, 40, 64, 52, 44, 64, 43, 91, 56,
    64, 57, 91,
  ]);
  static const chairfig4 = StretchPose([
    55, 24, 50, 33, 42, 60, 56, 46, 60, 55, 58, 48, 62, 62, 60, 54, 62, 64, 60,
    62, 60, 91,
  ]);
  static const seatedfold = StretchPose([
    60, 66, 52, 68, 30, 86, 64, 76, 74, 84, 63, 78, 73, 86, 52, 87, 76, 87, 52,
    88, 77, 88, 4,
  ]);
  static const butterfly = StretchPose([
    50, 44, 50, 54, 50, 82, 42, 70, 48, 84, 58, 70, 52, 84, 30, 80, 47, 88, 70,
    80, 53, 88,
  ]);
  static const seatedtwist = StretchPose([
    55, 45, 50, 54, 50, 82, 58, 64, 64, 78, 38, 66, 36, 82, 32, 82, 58, 88, 68,
    82, 44, 88,
  ]);
  static const strap = StretchPose([
    78, 85, 68, 86, 42, 86, 56, 72, 48, 58, 57, 74, 49, 60, 38, 66, 34, 46, 28,
    87, 14, 87,
  ]);
  static const kneehug = StretchPose([
    78, 85, 68, 86, 42, 86, 62, 74, 52, 66, 60, 76, 51, 70, 52, 68, 40, 72, 28,
    87, 14, 87,
  ]);
  static const fig4 = StretchPose([
    78, 85, 68, 86, 42, 86, 58, 72, 44, 66, 58, 74, 40, 70, 48, 64, 34, 66, 36,
    66, 26, 74,
  ]);
  static const supinetwist = StretchPose([
    78, 85, 68, 86, 42, 86, 72, 88, 80, 89, 70, 78, 72, 70, 44, 78, 34, 88, 28,
    87, 14, 87,
  ]);
  static const child = StretchPose([
    68, 86, 60, 84, 30, 80, 76, 86, 88, 88, 75, 87, 87, 89, 50, 89, 24, 90, 50,
    90, 25, 91, 3,
  ]);
  static const catcow = StretchPose([
    72, 52, 64, 60, 34, 60, 64, 74, 64, 88, 63, 74, 63, 89, 34, 88, 18, 88, 35,
    89, 19, 89, -5,
  ]);
  static const lunge = StretchPose([
    49, 26, 48, 36, 46, 64, 50, 20, 52, 10, 51, 21, 53, 11, 64, 72, 66, 91, 30,
    89, 16, 90,
  ]);
  static const cobra = StretchPose([
    72, 62, 64, 70, 40, 86, 66, 80, 66, 89, 65, 81, 65, 90, 24, 88, 10, 88, 24,
    89, 10, 89, -3,
  ]);
  static const downdog = StretchPose([
    70, 72, 66, 62, 48, 40, 74, 74, 80, 89, 73, 75, 79, 90, 38, 64, 28, 90, 37,
    65, 27, 91,
  ]);
  static const pigeon = StretchPose([
    52, 40, 50, 50, 44, 78, 56, 66, 58, 86, 44, 66, 40, 86, 60, 86, 48, 90, 26,
    88, 10, 89,
  ]);
  static const thread = StretchPose([
    70, 86, 64, 80, 36, 62, 60, 88, 48, 89, 70, 74, 74, 88, 36, 88, 20, 88, 37,
    89, 21, 89, 2,
  ]);
  static const roller = StretchPose([
    80, 82, 70, 80, 40, 86, 84, 72, 92, 78, 83, 73, 91, 79, 30, 68, 22, 88, 31,
    69, 23, 89,
  ]);
  static const bandpull = StretchPose([
    50, 17, 50, 27, 50, 55, 38, 29, 26, 30, 62, 29, 74, 30, 47, 73, 46, 91, 53,
    73, 54, 91,
  ]);
  static const bridge = StretchPose([
    80, 85, 70, 84, 42, 78, 60, 88, 50, 89, 61, 89, 51, 90, 30, 66, 26, 90, 31,
    67, 25, 90,
  ]);
  static const halfsplit = StretchPose([
    70, 66, 62, 62, 40, 66, 60, 76, 60, 88, 59, 77, 58, 89, 58, 80, 76, 88, 40,
    89, 24, 90, 3,
  ]);
  static const torsotwist = StretchPose([
    53, 17, 50, 27, 50, 55, 38, 32, 28, 38, 56, 34, 46, 40, 47, 73, 46, 91, 53,
    73, 54, 91,
  ]);

  // The three poses the prototype gives an authored second frame to
  // breathe/sway between (its `DYN_POSES`), instead of the default subtle
  // lift every other pose uses.
  static const catcowB = StretchPose([
    70, 72, 64, 64, 34, 62, 64, 76, 64, 88, 63, 76, 63, 89, 34, 88, 18, 88, 35,
    89, 19, 89, 7,
  ]);
  static const torsotwistB = StretchPose([
    47, 17, 50, 27, 50, 55, 44, 34, 54, 40, 62, 32, 72, 38, 47, 73, 46, 91, 53,
    73, 54, 91,
  ]);
  static const bandpullB = StretchPose([
    50, 17, 50, 27, 50, 55, 36, 29, 20, 31, 64, 29, 80, 31, 47, 73, 46, 91, 53,
    73, 54, 91,
  ]);

  /// Poses with an authored second frame — looked up by identity, same as
  /// the prototype's `DYN_POSES` — and their faster breathing period.
  static final Map<StretchPose, StretchPose> dynamicBreathPartners = {
    catcow: catcowB,
    torsotwist: torsotwistB,
    bandpull: bandpullB,
  };
}

/// The pose this figure eases toward and back from while holding, forever
/// — mirrors the prototype's `lerpPose(POSES[pose], t)`.
StretchPose _breathPartnerFor(StretchPose pose) =>
    StretchPoses.dynamicBreathPartners[pose] ?? pose.defaultBreathPartner;

/// A full breathe-in/breathe-out cycle: 3.4s for the three poses with real
/// back-and-forth movement, 5.6s of gentle sway for everything else —
/// mirrors the prototype's `P.dyn?3400:5600`.
Duration _breathPeriodFor(StretchPose pose) =>
    StretchPoses.dynamicBreathPartners.containsKey(pose)
    ? const Duration(milliseconds: 3400)
    : const Duration(milliseconds: 5600);

/// Renders a [StretchPose] exactly like the prototype's `fig()` SVG: a
/// ground line plus a five-stroke stick figure (far arm, far leg, torso,
/// near leg, near arm, head), scaled from its 0–100 grid to fill the
/// widget's box.
class StretchFigure extends StatelessWidget {
  const StretchFigure({super.key, required this.pose, this.showGround = true});

  final StretchPose pose;
  final bool showGround;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return CustomPaint(
      size: Size.infinite,
      painter: StretchFigurePainter(
        pose: pose,
        nearColor: colors.ink,
        farColor: colors.figFar,
        groundColor: colors.line,
        showGround: showGround,
      ),
    );
  }
}

/// [StretchFigure], but alive: instead of sitting perfectly still, it
/// breathes gently between [pose] and a lightly offset counterpart,
/// forever, for as long as it's on screen — mirrors the prototype's
/// `startFigAnim()`/`figLoop()`, which animates every hero figure (get
/// ready, the session player, the stretch-detail sheet) this same way
/// regardless of which routine or stretch is showing.
///
/// Respects "reduce motion": when the platform asks for it, the figure
/// holds its exact [pose] instead, matching the prototype's own
/// `prefers-reduced-motion` check.
class AnimatedStretchFigure extends StatefulWidget {
  const AnimatedStretchFigure({
    super.key,
    required this.pose,
    this.showGround = true,
    this.nearColor,
    this.farColor,
    this.groundColor,
  });

  final StretchPose pose;
  final bool showGround;

  /// Colors to paint with; default to the current theme's figure colors
  /// (the same ones [StretchFigure] uses) when left unset.
  final Color? nearColor;
  final Color? farColor;
  final Color? groundColor;

  @override
  State<AnimatedStretchFigure> createState() => _AnimatedStretchFigureState();
}

class _AnimatedStretchFigureState extends State<AnimatedStretchFigure>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: _breathPeriodFor(widget.pose) ~/ 2,
  )..repeat(reverse: true);
  late final Animation<double> _sway = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeInOut,
  );

  @override
  void didUpdateWidget(covariant AnimatedStretchFigure oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pose != widget.pose) {
      final period = _breathPeriodFor(widget.pose) ~/ 2;
      if (period != _controller.duration) _controller.duration = period;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final reduceMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    return AnimatedBuilder(
      animation: _sway,
      builder: (context, _) {
        final pose = reduceMotion
            ? widget.pose
            : widget.pose.lerp(_breathPartnerFor(widget.pose), _sway.value);
        return CustomPaint(
          size: Size.infinite,
          painter: StretchFigurePainter(
            pose: pose,
            nearColor: widget.nearColor ?? colors.ink,
            farColor: widget.farColor ?? colors.figFar,
            groundColor: widget.groundColor ?? colors.line,
            showGround: widget.showGround,
          ),
        );
      },
    );
  }
}

@immutable
class StretchFigurePainter extends CustomPainter {
  const StretchFigurePainter({
    required this.pose,
    required this.nearColor,
    required this.farColor,
    required this.groundColor,
    required this.showGround,
  });

  /// The prototype's 0–100 SVG viewBox.
  static const double _gridSize = 100;

  final StretchPose pose;
  final Color nearColor;
  final Color farColor;
  final Color groundColor;
  final bool showGround;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.shortestSide / _gridSize;
    final origin = Offset(
      (size.width - _gridSize * scale) / 2,
      (size.height - _gridSize * scale) / 2,
    );
    Offset at(int jointIndex) => pose.jointAt(jointIndex) * scale + origin;

    if (showGround) {
      canvas.drawLine(
        Offset(4, 92) * scale + origin,
        Offset(96, 92) * scale + origin,
        _stroke(groundColor, 1.5, scale),
      );
    }

    final neck = at(1);
    final hip = at(2);
    final farPaint = _stroke(farColor, 5, scale);
    _polyline(canvas, [neck, at(5), at(6)], farPaint);
    _polyline(canvas, [hip, at(9), at(10)], farPaint);

    canvas.drawPath(
      _torsoPath(neck, hip, pose.archAmount * scale),
      _stroke(nearColor, 6.5, scale),
    );

    final nearPaint = _stroke(nearColor, 5, scale);
    _polyline(canvas, [hip, at(7), at(8)], nearPaint);
    _polyline(canvas, [neck, at(3), at(4)], nearPaint);

    canvas.drawCircle(at(0), 5.8 * scale, Paint()..color = nearColor);
  }

  /// Mirrors the prototype's `torsoD()`: a quadratic curve from neck to
  /// hip, bowed sideways by [scaledArch] perpendicular to that line.
  Path _torsoPath(Offset neck, Offset hip, double scaledArch) {
    final delta = hip - neck;
    final length = delta.distance == 0 ? 1.0 : delta.distance;
    final control =
        (neck + hip) / 2 +
        Offset(-delta.dy, delta.dx) / length * (scaledArch * 2);
    return Path()
      ..moveTo(neck.dx, neck.dy)
      ..quadraticBezierTo(control.dx, control.dy, hip.dx, hip.dy);
  }

  Paint _stroke(Color color, double width, double scale) => Paint()
    ..color = color
    ..style = PaintingStyle.stroke
    ..strokeWidth = width * scale
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;

  void _polyline(Canvas canvas, List<Offset> points, Paint paint) {
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (final point in points.skip(1)) {
      path.lineTo(point.dx, point.dy);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant StretchFigurePainter oldDelegate) =>
      oldDelegate.pose != pose ||
      oldDelegate.nearColor != nearColor ||
      oldDelegate.farColor != farColor ||
      oldDelegate.groundColor != groundColor ||
      oldDelegate.showGround != showGround;
}
