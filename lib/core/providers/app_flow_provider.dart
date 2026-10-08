import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fitness_app/core/providers/custom_routines_provider.dart';
import 'package:fitness_app/core/providers/favorites_provider.dart';
import 'package:fitness_app/core/providers/home_tab_provider.dart';
import 'package:fitness_app/core/providers/hurt_stretches_provider.dart';
import 'package:fitness_app/core/providers/plan_overview_provider.dart';
import 'package:fitness_app/core/providers/todays_plan_provider.dart';
import 'package:fitness_app/features/profile/providers/premium_provider.dart';
import 'package:fitness_app/features/profile/providers/reminders_provider.dart';
import 'package:fitness_app/features/profile/providers/session_settings_provider.dart';
import 'package:fitness_app/services/reminder_notification_service.dart';

import 'package:fitness_app/core/providers/auth_service_provider.dart';
import 'package:fitness_app/features/onboarding_setup/providers/onboarding_profile_provider.dart';

/// Top-level screen the app is currently showing. Drives `home:` in
/// [MaterialApp] directly, so navigation between these top-level screens
/// needs no `Navigator` plumbing — any widget can advance the flow with
/// `ref.read(appFlowProvider.notifier)`.
enum AppRoute {
  splash,
  welcome,
  login,
  signup,
  verifyEmail,
  forgotPassword,
  resetPassword,
  onboarding,
  planReady,
  home,
}

class AppFlowController extends Notifier<AppRoute> {
  @override
  AppRoute build() => AppRoute.splash;

  /// Called once the splash screen's beat finishes.
  void finishSplash() => state = AppRoute.welcome;

  /// Back from login/signup, or any "not now" exit back to welcome.
  void showWelcome() => state = AppRoute.welcome;

  void showLogin() => state = AppRoute.login;

  void showSignup() => state = AppRoute.signup;

  /// After a signup submission, until the 6-digit code is confirmed.
  void showVerifyEmail() => state = AppRoute.verifyEmail;

  void showForgotPassword() => state = AppRoute.forgotPassword;

  /// After a forgot-password submission, until the new password is set.
  void showResetPassword() => state = AppRoute.resetPassword;

  /// After a fresh signup verifies, before the account has a profile.
  void showOnboarding() => state = AppRoute.onboarding;

  /// The setup wizard's last step just built a plan — reveal it before the
  /// tabbed home shell.
  void showPlanReady() => state = AppRoute.planReady;

  /// After email or Google sign-in succeeds: loads the saved profile, then
  /// lands on Home for a finished account or the setup wizard for a new one.
  Future<void> enterAfterSignIn() async {
    var isOnboardingComplete = false;
    try {
      final res = await ref.read(authServiceProvider).getMe();
      final userData =
          (res['user'] ?? res['data'] ?? res) as Map<String, dynamic>;
      isOnboardingComplete = userData['onboardingComplete'] == true;
      ref.read(onboardingProfileProvider.notifier).loadFromApi(userData);
      ref.read(sessionSettingsProvider.notifier).loadFromApi(userData);
    } catch (_) {}
    if (isOnboardingComplete) {
      enterApp();
    } else {
      showOnboarding();
    }
  }

  /// Clears everything tied to the signed-in account (call after the session
  /// is gone) so the next account starts clean, on the Today tab.
  Future<void> resetUserState() async {
    ref.invalidate(homeTabProvider);
    ref.invalidate(onboardingProfileProvider);
    ref.invalidate(sessionSettingsProvider);
    ref.invalidate(premiumProvider);
    ref.invalidate(customRoutinesProvider);
    ref.invalidate(favoritesProvider);
    ref.invalidate(hurtStretchesProvider);
    ref.invalidate(remindersProvider);
    ref.invalidate(deskNudgeProvider);
    ref.invalidate(todaysPlanProvider);
    ref.invalidate(planOverviewProvider);
    await ReminderNotificationService.instance.cancelAll();
  }

  /// A successful login, "Explore with a sample account" on the welcome
  /// screen, or leaving the plan-reveal screen — all land here since
  /// there's no backend yet.
  void enterApp() => state = AppRoute.home;
}

final appFlowProvider = NotifierProvider<AppFlowController, AppRoute>(
  AppFlowController.new,
);
