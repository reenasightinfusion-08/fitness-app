import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fitness_app/core/theme/theme.dart';
import 'package:fitness_app/core/widgets/stretch_placeholder.dart';

final fadeFinder = find.descendant(
  of: find.byType(StretchPlaceholder),
  matching: find.byType(FadeTransition),
);

Widget host(Widget child) => MaterialApp(
  theme: AppTheme.light,
  home: SizedBox(width: 120, height: 90, child: child),
);

void main() {
  testWidgets('shows a still image icon when the media is unavailable', (
    tester,
  ) async {
    await tester.pumpWidget(host(const StretchPlaceholder()));

    expect(find.byIcon(Icons.image_outlined), findsOneWidget);
    final fade = tester.widget<FadeTransition>(fadeFinder);
    expect(fade.opacity.value, 1);
  });

  testWidgets('pulses while loading and settles once loaded', (tester) async {
    await tester.pumpWidget(host(const StretchPlaceholder(isLoading: true)));
    await tester.pump(const Duration(milliseconds: 550));
    final fade = tester.widget<FadeTransition>(fadeFinder);
    expect(fade.opacity.value, lessThan(1));
    expect(find.byIcon(Icons.image_outlined), findsNothing);

    await tester.pumpWidget(host(const StretchPlaceholder()));
    await tester.pump();
    expect(tester.widget<FadeTransition>(fadeFinder).opacity.value, 1);
  });
}
