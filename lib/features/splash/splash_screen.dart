import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:fitness_app/core/providers/providers.dart';
import 'package:fitness_app/core/theme/theme.dart';
import 'package:fitness_app/core/widgets/widgets.dart';

/// Matches the prototype's `screens.splash` view: brand mark + wordmark,
/// centered, with a one-line tagline underneath. Auto-advances to the
/// welcome screen after a short beat, same as the prototype's 900ms
/// timeout — driven through [appFlowProvider] instead of a callback.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => SplashScreenState();
}

class SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 900), () {
      if (mounted) ref.read(appFlowProvider.notifier).finishSplash();
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      backgroundColor: colors.ground,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const AppBrandLogo(isLarge: true),
            10.verticalSpace,
            Text(
              'Stretching that fits your body.',
              style: AppTextStyle.bodyMedium.copyWith(color: colors.ink2),
            ),
          ],
        ),
      ),
    );
  }
}
