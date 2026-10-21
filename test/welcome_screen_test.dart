import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fitness_app/core/providers/providers.dart';
import 'package:fitness_app/core/theme/theme.dart';
import 'package:fitness_app/features/welcome/welcome_screen.dart';
import 'package:fitness_app/services/auth_service.dart';

class _FakeAuth implements AuthService {
  @override
  void Function()? onSessionExpired;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<ProviderContainer> pumpWelcome(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final container = ProviderContainer(
    overrides: [authServiceProvider.overrideWithValue(_FakeAuth())],
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: ScreenUtilInit(
        designSize: const Size(390, 844),
        builder: (_, _) =>
            MaterialApp(theme: AppTheme.light, home: const WelcomeScreen()),
      ),
    ),
  );
  await tester.pump();
  return container;
}

void main() {
  for (final size in const [
    Size(360, 560),
    Size(411, 900),
    Size(768, 1024), // Tablet portrait
    Size(1024, 768), // Tablet landscape
    Size(1280, 800), // Widescreen tablet
  ]) {
    testWidgets('welcome offers sign up and login only at $size', (
      tester,
    ) async {
      await pumpWelcome(tester, size);

      expect(find.text('Get started'), findsOneWidget);
      expect(find.text('I already have an account'), findsOneWidget);
      expect(find.textContaining('sample'), findsNothing);
      if (size.height >= 700) {
        expect(find.text('Voice-guided'), findsOneWidget);
        expect(find.text('Built for your body'), findsOneWidget);
        expect(find.text('Any equipment'), findsOneWidget);
      }
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('the two buttons open signup and login', (tester) async {
    final container = await pumpWelcome(tester, const Size(411, 900));

    await tester.ensureVisible(find.text('I already have an account'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('I already have an account'));
    await tester.pumpAndSettle();
    expect(container.read(appFlowProvider), AppRoute.login);

    container.read(appFlowProvider.notifier).showWelcome();
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Get started'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Get started'));
    await tester.pumpAndSettle();
    expect(container.read(appFlowProvider), AppRoute.signup);
  });
}
