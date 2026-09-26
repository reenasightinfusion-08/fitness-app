import 'package:flutter/material.dart';

import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:fitness_app/core/theme/theme.dart';
import 'package:fitness_app/core/widgets/app_icon_button.dart';

/// Back button · centred title (or any [center] widget, e.g. a progress bar) · trailing slot.
/// Side slots are always reserved so the title stays optically centred.
class AppTopBar extends StatelessWidget implements PreferredSizeWidget {
  const AppTopBar({
    super.key,
    this.title,
    this.center,
    this.onBack,
    this.trailing,
    this.backgroundColor,
    this.isOnDark = false,
  });

  final String? title;
  final Widget? center;
  final VoidCallback? onBack;
  final Widget? trailing;
  final Color? backgroundColor;
  final bool isOnDark;

  @override
  Size get preferredSize => Size.fromHeight(54.h);

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Material(
      color: backgroundColor ?? colors.ground,
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: 54.h,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 10.w),
            child: Row(
              children: [
                SizedBox(
                  width: 42.r,
                  child: onBack == null
                      ? null
                      : AppIconButton(
                          icon: Icons.arrow_back_ios_new_rounded,
                          tooltip: 'Back',
                          onPressed: onBack,
                          isOnDark: isOnDark,
                        ),
                ),
                8.horizontalSpace,
                Expanded(
                  child:
                      center ??
                      Text(
                        title ?? '',
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyle.titleMedium.copyWith(
                          color: isOnDark ? colors.playerInk : colors.ink,
                        ),
                      ),
                ),
                8.horizontalSpace,
                ConstrainedBox(
                  constraints: BoxConstraints(minWidth: 42.r),
                  child: trailing ?? const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
