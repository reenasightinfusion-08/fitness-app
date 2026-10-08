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
    return AspectRatio(
      aspectRatio: 16 / 12,
      child: ClipRRect(
        borderRadius: AppBorderRadius.hero,
       child: Image.asset('assets/images/welcome_hero.jpg',fit: BoxFit.cover,),
      )
    );
  }
}
