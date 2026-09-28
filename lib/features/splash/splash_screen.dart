import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:fitness_app/core/providers/providers.dart';
import 'package:fitness_app/core/theme/theme.dart';
import 'package:fitness_app/core/widgets/widgets.dart';

/// Matches the prototype's `screens.splash` view: brand mark + wordmark,
/// centered, with a one-line tagline underneath. After a short beat it
/// checks for a stored session token — straight to home if one exists,
/// otherwise on to the welcome screen — driven through [appFlowProvider]
/// instead of a callback.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => SplashScreenState();
}

class SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 900), () async {
      if (!mounted) return;
      final hasSession = await ref.read(authServiceProvider).hasSession();
      if (!mounted) return;
      final flow = ref.read(appFlowProvider.notifier);
      hasSession ? flow.enterApp() : flow.finishSplash();
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
