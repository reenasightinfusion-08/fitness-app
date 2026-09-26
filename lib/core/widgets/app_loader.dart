import 'package:flutter/material.dart';

import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:fitness_app/core/theme/theme.dart';

class AppLoader extends StatelessWidget {
  const AppLoader({
    super.key,
    this.size = 24,
    this.color,
    this.strokeWidth = 2.5,
  });

  final double size;
  final Color? color;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: size.r,
    child: CircularProgressIndicator(
      strokeWidth: strokeWidth,
      strokeCap: StrokeCap.round,
      color: color ?? context.colors.accent,
    ),
  );
}
