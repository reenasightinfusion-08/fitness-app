import 'package:flutter/material.dart';

import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:fitness_app/core/theme/theme.dart';
import 'package:fitness_app/core/widgets/app_selection_indicator.dart';

/// Full-width choice card. Use [AppSelectionShape.checkbox] for multi-select
/// questions and for consent checkboxes.
class AppOptionTile extends StatelessWidget {
  const AppOptionTile({
    super.key,
    required this.title,
    required this.isSelected,
    required this.onTap,
    this.subtitle,
    this.shape = AppSelectionShape.radio,
    this.leading,
  });

  final String title;
  final String? subtitle;
  final bool isSelected;
  final VoidCallback? onTap;
  final AppSelectionShape shape;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final size = MediaQuery.sizeOf(context);
    final isTablet = size.width >= 600;

    final radius = AppBorderRadius.xl;
    final padH = isTablet ? 16.0 : 16.w;
    final padV = isTablet ? 14.0 : 14.h;
    final titleFontSize = isTablet ? 16.0 : null;
    final subFontSize = isTablet ? 14.0 : null;

    return Semantics(
      selected: isSelected,
      button: true,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: isSelected ? colors.accentSoft : colors.surface,
          borderRadius: radius,
          border: Border.all(
            color: isSelected ? colors.accent : colors.line,
            width: 1.5,
          ),
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: onTap,
            borderRadius: radius,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: padH, vertical: padV),
              child: Row(
                children: [
                  AppSelectionIndicator(isSelected: isSelected, shape: shape),
                  (isTablet ? 16.0 : 12.0).horizontalSpace,
                  if (leading != null) ...[
                    leading!,
                    (isTablet ? 16.0 : 12.0).horizontalSpace,
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: AppTextStyle.titleSmall.copyWith(
                            fontSize: titleFontSize,
                          ),
                        ),
                        if (subtitle != null) ...[
                          if (isTablet) const SizedBox(height: 4.0),
                          Text(
                            subtitle!,
                            style: AppTextStyle.meta.copyWith(
                              color: colors.ink2,
                              fontSize: subFontSize,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
