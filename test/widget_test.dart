import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fitness_app/core/providers/providers.dart';
import 'package:fitness_app/services/auth_service.dart';

class _FakeAuth implements AuthService {
  _FakeAuth({this.session = true, this.cachedOnboarded = false});

  bool session;
  bool cachedOnboarded;

  @override
  void Function()? onSessionExpired;

  @override
  Future<bool> hasSession() async => session;

  @override
  Future<bool> onboardingCompleteCached() async => cachedOnboarded;

  @override
  Future<Map<String, dynamic>> getMe() async =>
      throw AuthException("Couldn't reach the server. Check your connection.");

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

ProviderContainer _container(_FakeAuth auth) {
  final container = ProviderContainer(
    overrides: [authServiceProvider.overrideWithValue(auth)],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  // GlobalKey.currentState (used by sessionExpired) needs a widgets binding.
  TestWidgetsFlutterBinding.ensureInitialized();

  test('the app starts on the splash screen and hooks up session expiry', () {
    final auth = _FakeAuth();
    final container = _container(auth);

    expect(container.read(appFlowProvider), AppRoute.splash);
    expect(auth.onSessionExpired, isNotNull);
  });

  test('a returning user reaches Home when the profile cannot be loaded', () async {
    final container = _container(_FakeAuth(cachedOnboarded: true));

    await container.read(appFlowProvider.notifier).enterAfterSignIn();

    expect(container.read(appFlowProvider), AppRoute.home);
  });

  test('a new account goes to setup when the profile cannot be loaded', () async {
    final container = _container(_FakeAuth());

    await container.read(appFlowProvider.notifier).enterAfterSignIn();

    expect(container.read(appFlowProvider), AppRoute.onboarding);
  });

  test('sign-in does not move on once the session has been cleared', () async {
    final container = _container(_FakeAuth(session: false));

    await container.read(appFlowProvider.notifier).enterAfterSignIn();

    expect(container.read(appFlowProvider), AppRoute.splash);
  });

  test('an expired session sends a signed-in user back to welcome', () async {
    final container = _container(_FakeAuth());
    final flow = container.read(appFlowProvider.notifier)..enterApp();

    try {
      await flow.sessionExpired();
    } catch (_) {
      // Clearing reminders needs the notification plugin, absent in unit tests.
    }

    expect(container.read(appFlowProvider), AppRoute.welcome);
  });

  test('an expired session is ignored while already signed out', () async {
    final container = _container(_FakeAuth());
    final flow = container.read(appFlowProvider.notifier)..showLogin();

    await flow.sessionExpired();

    expect(container.read(appFlowProvider), AppRoute.login);
  });
}
