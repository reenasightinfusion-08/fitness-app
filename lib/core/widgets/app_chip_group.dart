import 'package:flutter/material.dart';

import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Lays chips out wrapping, or in one horizontally scrolling line
/// that bleeds to the screen edge ([isScrollable]).
class AppChipGroup extends StatelessWidget {
  const AppChipGroup({
    super.key,
    required this.children,
    this.isScrollable = false,
  });

  final List<Widget> children;
  final bool isScrollable;

  @override
  Widget build(BuildContext context) {
    if (!isScrollable) {
      return Wrap(spacing: 8.w, runSpacing: 8.h, children: children);
    }
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.none,
      child: Row(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) 8.horizontalSpace,
            children[i],
          ],
        ],
      ),
    );
  }
}
