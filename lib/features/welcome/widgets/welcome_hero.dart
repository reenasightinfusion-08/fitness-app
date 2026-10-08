import 'package:flutter/material.dart';

import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:fitness_app/core/theme/theme.dart';
import 'package:fitness_app/core/widgets/widgets.dart';

/// The prototype's `.hero-fig`: an accent-soft panel holding the "reach"
/// stretch figure, same 16:10 proportions.
class WelcomeHero extends StatelessWidget {
  const WelcomeHero({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return AspectRatio(
      aspectRatio: 16 / 10,
      child: ClipRRect(
        borderRadius: AppBorderRadius.hero,
       // child: Image.asset('assets/images/welcome_hero_real.jpg',fit: BoxFit.cover,),
        child: Image.asset('assets/images/loosen_hero.jpg',fit: BoxFit.cover,),
      )
      // Container(
      //   decoration: BoxDecoration(
      //     color: colors.accentSoft,
      //     borderRadius: AppBorderRadius.hero,
      //   ),
      //   padding: EdgeInsets.all(28.r),
      //   child: const FractionallySizedBox(
      //     widthFactor: 0.62,
      //     heightFactor: 0.62,
      //     child: StretchFigure(pose: StretchPoses.reach, showGround: false),
      //   ),
      // ),
    );
  }
}
