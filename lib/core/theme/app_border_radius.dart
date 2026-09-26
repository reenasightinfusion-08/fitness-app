import 'package:flutter/material.dart';

import 'package:flutter_screenutil/flutter_screenutil.dart';

class AppBorderRadius {
  const AppBorderRadius._();

  /// Stepper buttons, small inner pieces.
  static BorderRadius get xs => BorderRadius.circular(8.r);

  /// Segmented thumb, calendar cells.
  static BorderRadius get sm => BorderRadius.circular(10.r);

  /// Icon buttons, small buttons, segmented track, toast.
  static BorderRadius get md => BorderRadius.circular(12.r);

  /// Inputs, thumbnails, fact tiles.
  static BorderRadius get lg => BorderRadius.circular(14.r);

  /// Primary buttons, option tiles, notes.
  static BorderRadius get xl => BorderRadius.circular(16.r);

  /// Routine cards, quick picks.
  static BorderRadius get xxl => BorderRadius.circular(18.r);

  /// Surface cards.
  static BorderRadius get card => BorderRadius.circular(20.r);

  /// Hero illustrations.
  static BorderRadius get hero => BorderRadius.circular(24.r);

  static BorderRadius get pill => BorderRadius.circular(999.r);

  static BorderRadius get sheet =>
      BorderRadius.vertical(top: Radius.circular(26.r));
}

class AppInsets {
  const AppInsets._();

  static EdgeInsets get page => EdgeInsets.fromLTRB(18.w, 14.h, 18.w, 28.h);
  static EdgeInsets get card => EdgeInsets.all(16.r);
}
