import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

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
  runApp(const ProviderScope(child: FitnessApp()));
}

class FitnessApp extends ConsumerWidget {
  const FitnessApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final route = ref.watch(appFlowProvider);
    final themeMode = ref.watch(themeModeProvider);
    // Loads the saved reminders and schedules them as soon as the user is in.
    if (route == AppRoute.home) ref.watch(remindersProvider);

    return ScreenUtilInit(
      designSize: const Size(390, 844),
      minTextAdapt: true,
      builder: (context, child) => MaterialApp(
        title: 'Loosen',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: themeMode,
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
