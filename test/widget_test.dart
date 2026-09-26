import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fitness_app/features/onboarding/onboarding_screen.dart';
import 'package:fitness_app/features/onboarding/widgets/onboarding_next_button.dart';
import 'package:fitness_app/main.dart';

void main() {
  for (final size in const [Size(390, 844), Size(375, 667), Size(430, 932)]) {
    testWidgets('Onboarding lays out on ${size.width.toInt()}x${size.height.toInt()}', (tester) async {
      tester.view.physicalSize = size * 3;
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(const FitnessApp());
      await tester.pump();
      expect(find.byType(OnboardingScreen), findsOneWidget);

      for (var page = 0; page < 2; page++) {
        await tester.tap(find.byType(OnboardingNextButton));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pump(const Duration(milliseconds: 300));
      }
      expect(find.text('Get started'), findsOneWidget);
    });
  }
}
