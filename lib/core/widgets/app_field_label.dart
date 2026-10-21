import 'package:flutter/material.dart';

import 'package:fitness_app/core/theme/theme.dart';

class AppFieldLabel extends StatelessWidget {
  const AppFieldLabel({super.key, required this.text, this.isOptional = false});

  final String text;
  final bool isOptional;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final size = MediaQuery.sizeOf(context);
    final isTablet = size.width >= 600;
    final labelSize = isTablet ? 20.0 : null;
    final optSize = isTablet ? 16.0 : null;

    return Text.rich(
      TextSpan(
        text: text,
        children: [
          if (isOptional)
            TextSpan(
              text: '  optional',
              style: AppTextStyle.label.copyWith(
                fontWeight: FontWeight.w500,
                color: colors.ink3,
                fontSize: optSize,
              ),
            ),
        ],
      ),
      style: AppTextStyle.label.copyWith(
        color: colors.ink2,
        fontSize: labelSize,
      ),
    );
  }
}
