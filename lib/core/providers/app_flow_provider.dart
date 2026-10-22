import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fitness_app/core/providers/custom_routines_provider.dart';
import 'package:fitness_app/core/providers/favorites_provider.dart';
import 'package:fitness_app/core/providers/home_tab_provider.dart';
import 'package:fitness_app/core/providers/hurt_stretches_provider.dart';
import 'package:fitness_app/core/providers/plan_overview_provider.dart';
import 'package:fitness_app/core/providers/todays_plan_provider.dart';
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

/// Lets the app pop pushed routes (session player, sheets) when it has to
/// jump back to sign-in from outside the widget tree.
final rootNavigatorKey = GlobalKey<NavigatorState>();

const _signedOutRoutes = {
  AppRoute.welcome,
  AppRoute.login,
  AppRoute.signup,
  AppRoute.verifyEmail,
  AppRoute.forgotPassword,
  AppRoute.resetPassword,
};

class AppFlowController extends Notifier<AppRoute> {
  @override
  AppRoute build() {
    ref.read(authServiceProvider).onSessionExpired = sessionExpired;
    return AppRoute.splash;
  }

  /// The server rejected the saved token, so the user has to sign in again.
  Future<void> sessionExpired() async {
    if (_signedOutRoutes.contains(state)) return;
    rootNavigatorKey.currentState?.popUntil((route) => route.isFirst);
    showWelcome();
    await resetUserState();
  }

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
    final auth = ref.read(authServiceProvider);
    var isOnboardingComplete = false;
    try {
      final res = await auth.getMe();
      final userData =
          (res['user'] ?? res['data'] ?? res) as Map<String, dynamic>;
      isOnboardingComplete = userData['onboardingComplete'] == true;
      ref.read(onboardingProfileProvider.notifier).loadFromApi(userData);
      ref.read(sessionSettingsProvider.notifier).loadFromApi(userData);
    } catch (e) {
      debugPrint('[AppFlow] Could not load the profile after sign-in: $e');
      isOnboardingComplete = await auth.onboardingCompleteCached();
    }
    if (!await auth.hasSession()) return;
    if (isOnboardingComplete) {
      enterApp();
    } else {
      showOnboarding();
    }
  }

  /// Clears everything tied to the signed-in account (call after the session
  /// is gone) so the next account starts clean, on the Today tab.
  Future<void> resetUserState() async {
    debugPrint('[resetUserState] a: start');
    ref.invalidate(homeTabProvider);
    debugPrint('[resetUserState] b: invalidated homeTabProvider');
    ref.invalidate(onboardingProfileProvider);
    debugPrint('[resetUserState] c: invalidated onboardingProfileProvider');
    ref.invalidate(sessionSettingsProvider);
    debugPrint('[resetUserState] d: invalidated sessionSettingsProvider');
    ref.invalidate(customRoutinesProvider);
    debugPrint('[resetUserState] e: invalidated customRoutinesProvider');
    ref.invalidate(favoritesProvider);
    debugPrint('[resetUserState] f: invalidated favoritesProvider');
    ref.invalidate(hurtStretchesProvider);
    debugPrint('[resetUserState] g: invalidated hurtStretchesProvider');
    ref.invalidate(remindersProvider);
    debugPrint('[resetUserState] h: invalidated remindersProvider');
    ref.invalidate(deskNudgeProvider);
    debugPrint('[resetUserState] i: invalidated deskNudgeProvider');
    ref.invalidate(todaysPlanProvider);
    debugPrint('[resetUserState] j: invalidated todaysPlanProvider');
    ref.invalidate(planOverviewProvider);
    debugPrint('[resetUserState] k: invalidated planOverviewProvider');
    try {
      await ReminderNotificationService.instance.cancelAll();
      debugPrint('[resetUserState] l: cancelAll finished');
    } catch (e, st) {
      debugPrint('[resetUserState] cancelAll threw error: $e\n$st');
    }
  }

  /// Shows the tabbed home shell: after a successful sign-in, leaving the
  /// plan-reveal screen, or finishing a session.
  void enterApp() => state = AppRoute.home;
}

final appFlowProvider = NotifierProvider<AppFlowController, AppRoute>(
  AppFlowController.new,
);
