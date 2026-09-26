import 'package:flutter/material.dart';

import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:fitness_app/core/theme/theme.dart';

class AppNavItemModel {
  const AppNavItemModel({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
}

/// Bottom tabs — mirrors the prototype's flat `.tabs`/`.tab`: icon + label
/// simply switch to the accent color on selection, no pill or background
/// shape. Only the color animates (via [TweenAnimationBuilder], so it
/// eases from whatever it currently is rather than restarting); the icon
/// swap and scale bump are instant/one-shot per tab, so tapping one tab
/// never visibly animates its neighbor.
class AppBottomNav extends StatelessWidget {
  const AppBottomNav({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
  });

  final List<AppNavItemModel> items;
  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(top: BorderSide(color: colors.line)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 5.h),
          child: Row(
            children: [
              for (var i = 0; i < items.length; i++)
                Expanded(
                  child: AppBottomNavTab(
                    item: items[i],
                    isActive: i == currentIndex,
                    onTap: () => onTap(i),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class AppBottomNavTab extends StatelessWidget {
  const AppBottomNavTab({
    super.key,
    required this.item,
    required this.isActive,
    required this.onTap,
  });

  final AppNavItemModel item;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final color = isActive ? colors.accent : colors.ink3;
    return Semantics(
      selected: isActive,
      button: true,
      label: item.label,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppBorderRadius.md,
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 6.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedScale(
                duration: const Duration(milliseconds: 180),
                curve: isActive ? Curves.easeOutBack : Curves.easeOutCubic,
                scale: isActive ? 1.1 : 1.0,
                child: TweenAnimationBuilder<Color?>(
                  duration: const Duration(milliseconds: 180),
                  tween: ColorTween(end: color),
                  builder: (context, animatedColor, child) => Icon(
                    isActive ? item.activeIcon : item.icon,
                    size: 22.r,
                    color: animatedColor,
                  ),
                ),
              ),
              2.verticalSpace,
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 180),
                style: AppTextStyle.tab.copyWith(color: color),
                child: Text(item.label),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
