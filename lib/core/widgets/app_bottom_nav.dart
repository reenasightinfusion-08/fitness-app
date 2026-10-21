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
    // iPhones report a 34pt home-indicator inset, but the indicator is thin; using
    // all of it leaves a tall empty strip under the labels and the bar looks too
    // high. Android keeps the full inset.
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    final isIos = Theme.of(context).platform == TargetPlatform.iOS;
    final size = MediaQuery.sizeOf(context);
    final isTablet = size.width >= 600;

    final Widget tabRow = Row(
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
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(top: BorderSide(color: colors.line)),
      ),
      child: Padding(
        padding: EdgeInsets.only(
          bottom: isIos ? bottomInset * 0.4 : bottomInset,
        ),
        child: SafeArea(
          top: false,
          bottom: false,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isTablet ? 16.0 : 4.w,
              vertical: isTablet ? 6.0 : 5.h,
            ),
            child: isTablet
                ? Align(
                    alignment: Alignment.center,
                    heightFactor: 1.0,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 580.0),
                      child: tabRow,
                    ),
                  )
                : tabRow,
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
    final size = MediaQuery.sizeOf(context);
    final isTablet = size.width >= 600;

    return Semantics(
      selected: isActive,
      button: true,
      label: item.label,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppBorderRadius.md,
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: isTablet ? 10.0 : 6.h),
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
                    size: isTablet ? 28.0 : 22.r,
                    color: animatedColor,
                  ),
                ),
              ),
              (isTablet ? 4.0 : 2.0).verticalSpace,
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 180),
                style: AppTextStyle.tab.copyWith(
                  color: color,
                  fontSize: isTablet ? 15.0 : null,
                ),
                child: Text(item.label),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
