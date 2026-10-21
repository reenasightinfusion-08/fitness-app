import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:fitness_app/core/ads/ad_service.dart';
import 'package:fitness_app/core/providers/providers.dart';
import 'package:fitness_app/core/theme/theme.dart';
import 'package:fitness_app/features/auth/forgot_password_screen.dart';
import 'package:fitness_app/features/auth/login_screen.dart';
import 'package:fitness_app/features/auth/reset_password_screen.dart';
import 'package:fitness_app/features/auth/signup_screen.dart';
import 'package:fitness_app/features/auth/verify_email_screen.dart';
import 'package:fitness_app/features/home/home_screen.dart';
import 'package:fitness_app/features/onboarding_setup/onboarding_setup_screen.dart';
import 'package:fitness_app/features/plan_ready/plan_ready_screen.dart';
import 'package:fitness_app/features/profile/providers/reminders_provider.dart';
import 'package:fitness_app/features/splash/splash_screen.dart';
import 'package:fitness_app/features/welcome/welcome_screen.dart';
import 'package:fitness_app/services/paused_session_cache.dart';
import 'package:fitness_app/services/reminder_notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ReminderNotificationService.instance.init();
  await PausedSessionCache.init();
  AdService.initialize();
  runApp(const ProviderScope(child: FitnessApp()));
}

/// Counts open routes so app open ads never appear over a pushed screen
/// (session player, dialogs, sheets).
class _RouteDepth extends NavigatorObserver {
  int depth = 0;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) => depth++;

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) => depth--;

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      depth--;
}

final _routeDepth = _RouteDepth();

class FitnessApp extends ConsumerWidget {
  const FitnessApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final route = ref.watch(appFlowProvider);
    final themeMode = ref.watch(themeModeProvider);
    // Loads the saved reminders and schedules them as soon as the user is in.
    if (route == AppRoute.home) ref.watch(remindersProvider);

    AdService.appOpenGuard = () =>
        ref.read(appFlowProvider) == AppRoute.home && _routeDepth.depth <= 1;

    return ScreenUtilInit(
      designSize: const Size(390, 844),
      minTextAdapt: true,
      fontSizeResolver: (fontSize, instance) {
        final scale = instance.scaleText.clamp(0.85, 1.15);
        return fontSize * scale;
      },
      builder: (context, child) => MaterialApp(
        title: 'Loosen',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: themeMode,
        navigatorKey: rootNavigatorKey,
        navigatorObservers: [_routeDepth],
        home: switch (route) {
          AppRoute.splash => const SplashScreen(),
          AppRoute.welcome => const WelcomeScreen(),
          AppRoute.login => const LoginScreen(),
          AppRoute.signup => const SignupScreen(),
          AppRoute.verifyEmail => const VerifyEmailScreen(),
          AppRoute.forgotPassword => const ForgotPasswordScreen(),
          AppRoute.resetPassword => const ResetPasswordScreen(),
          AppRoute.onboarding => const OnboardingSetupScreen(),
          AppRoute.planReady => const PlanReadyScreen(),
          AppRoute.home => const HomeScreen(),
        },
      ),
    );
  }
}
