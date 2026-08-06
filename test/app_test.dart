import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:puff_and_crunch/app/app.dart';
import 'package:puff_and_crunch/app/router.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    appRouter.go('/');
  });

  testWidgets('splash loads the themed home screen', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: PuffAndCrunchApp()));
    await tester.pumpAndSettle();

    expect(find.text('Puff & Crunch'), findsOneWidget);
    expect(find.text('Island Match'), findsOneWidget);
    expect(find.text('Play'), findsOneWidget);
  });

  testWidgets('settings persist and reset requires confirmation', (
    tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: PuffAndCrunchApp()));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Reduced motion'));
    await tester.pump();
    final reducedMotion = tester.widget<SwitchListTile>(
      find.widgetWithText(SwitchListTile, 'Reduced motion'),
    );
    expect(reducedMotion.value, isTrue);

    await tester.tap(find.text('Reset progress'));
    await tester.pumpAndSettle();
    expect(find.text('Reset all progress?'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.text('Reset all progress?'), findsNothing);
  });

  testWidgets('map opens pre-level and gameplay screens', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: PuffAndCrunchApp()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Play'));
    await tester.pumpAndSettle();

    final lockedLevel = tester.widget<FilledButton>(
      find.byKey(const Key('level-2')),
    );
    expect(lockedLevel.onPressed, isNull);

    await tester.tap(find.byKey(const Key('level-1')));
    await tester.pumpAndSettle();
    expect(find.text('Goal: Reach 5,000 points'), findsOneWidget);

    await tester.tap(find.text('Start Level'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Level 1'), findsWidgets);
    expect(find.text('Moves: 20'), findsWidgets);
    expect(find.text('Score: 0'), findsOneWidget);

    await tester.tap(find.byTooltip('Pause'));
    await tester.pump();
    expect(find.text('Paused'), findsOneWidget);
    await tester.tap(find.text('Resume'));
    await tester.pump();
    expect(find.text('Paused'), findsNothing);
  });
}
