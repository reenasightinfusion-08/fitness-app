import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:fitness_app/core/providers/providers.dart';
import 'package:fitness_app/core/theme/theme.dart';
import 'package:fitness_app/core/widgets/widgets.dart';
import 'package:fitness_app/features/onboarding_setup/providers/onboarding_profile_provider.dart';

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
      final authService = ref.read(authServiceProvider);
      final hasSession = await authService.hasSession();
      if (!mounted) return;
      bool isOnboardingComplete = false;
      if (hasSession) {
        try {
          final res = await authService.getMe();
          final userData = (res['user'] ?? res['data'] ?? res) as Map<String, dynamic>;
          isOnboardingComplete = userData['onboardingComplete'] == true;
          if (mounted) {
            ref.read(onboardingProfileProvider.notifier).loadFromApi(userData);
          }
        } catch (_) {
          // Soft fallback if network fails
        }
      }
      if (!mounted) return;
      final flow = ref.read(appFlowProvider.notifier);
      if (hasSession) {
        if (isOnboardingComplete) {
          flow.enterApp();
        } else {
          flow.showOnboarding();
        }
      } else {
        flow.finishSplash();
      }
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
