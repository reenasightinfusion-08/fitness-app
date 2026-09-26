import 'package:flutter_riverpod/flutter_riverpod.dart';

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

  /// A successful login, "Explore with a sample account" on the welcome
  /// screen, or leaving the plan-reveal screen — all land here since
  /// there's no backend yet.
  void enterApp() => state = AppRoute.home;
}

final appFlowProvider = NotifierProvider<AppFlowController, AppRoute>(
  AppFlowController.new,
);
