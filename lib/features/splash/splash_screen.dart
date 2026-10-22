import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fitness_app/features/profile/providers/session_settings_provider.dart';
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

class SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );
    _scaleAnimation = Tween<double>(begin: 0.94, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: Curves.easeOutCubic,
      ),
    );
    _animController.forward();

    Future.delayed(const Duration(milliseconds: 900), () async {
      if (!mounted) return;
      final authService = ref.read(authServiceProvider);
      var hasSession = await authService.hasSession();
      if (!mounted) return;
      bool isOnboardingComplete = false;
      if (hasSession) {
        try {
          final res = await authService.getMe();
          final userData = (res['user'] ?? res['data'] ?? res) as Map<String, dynamic>;
          isOnboardingComplete = userData['onboardingComplete'] == true;
          if (mounted) {
            ref.read(onboardingProfileProvider.notifier).loadFromApi(userData);
            ref.read(sessionSettingsProvider.notifier).loadFromApi(userData);
          }
        } catch (e) {
          debugPrint('[Splash] Could not load the profile: $e');
          isOnboardingComplete = await authService.onboardingCompleteCached();
        }
      }
      if (!mounted) return;
      // A rejected token is cleared while loading the profile above.
      hasSession = hasSession && await authService.hasSession();
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
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isTablet = MediaQuery.sizeOf(context).width >= 600;

    return Scaffold(
      backgroundColor: colors.ground,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const AppBrandLogo(isLarge: true),
                (isTablet ? 16.0 : 10.0).verticalSpace,
                Text(
                  'Stretching that fits your body.',
                  style: (isTablet
                          ? AppTextStyle.body(19.0, weight: FontWeight.w500)
                          : AppTextStyle.bodyMedium)
                      .copyWith(
                        color: colors.ink2,
                        letterSpacing: isTablet ? 0.2 : null,
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
