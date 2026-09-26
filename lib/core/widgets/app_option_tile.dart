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

    return Semantics(
      selected: isSelected,
      button: true,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: isSelected ? colors.accentSoft : colors.surface,
          borderRadius: AppBorderRadius.xl,
          border: Border.all(
            color: isSelected ? colors.accent : colors.line,
            width: 1.5,
          ),
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: onTap,
            borderRadius: AppBorderRadius.xl,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
              child: Row(
                children: [
                  AppSelectionIndicator(isSelected: isSelected, shape: shape),
                  12.horizontalSpace,
                  if (leading != null) ...[leading!, 12.horizontalSpace],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: AppTextStyle.titleSmall),
                        if (subtitle != null)
                          Text(
                            subtitle!,
                            style: AppTextStyle.meta.copyWith(
                              color: colors.ink2,
                            ),
                          ),
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
