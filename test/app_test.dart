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
    expect(find.text('Play Adventure'), findsOneWidget);
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
    await tester.tap(find.text('Play Adventure'));
    await tester.pump();
    await _pumpUntilFound(tester, find.byKey(const Key('level-2')));

    final lockedLevel = tester.widget<Material>(
      find.byKey(const Key('level-2')),
    );
    final lockedInkWell = tester.widget<InkWell>(
      find.descendant(
        of: find.byKey(const Key('level-2')),
        matching: find.byType(InkWell),
      ),
    );
    expect(lockedLevel.color, Colors.transparent);
    expect(lockedInkWell.onTap, isNull);

    await tester.tap(find.byKey(const Key('level-1')));
    await tester.pumpAndSettle();
    expect(find.text('Reach 1890 points'), findsOneWidget);
    expect(find.textContaining('Bake a balanced recipe'), findsOneWidget);

    await tester.tap(find.text('Start Level'));
    await tester.pump();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(seconds: 3)),
    );
    for (var frame = 0; frame < 60; frame++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    expect(find.text('Level 1'), findsWidgets);
    expect(find.text('Moves: 27'), findsWidgets);
    expect(find.text('Score: 0'), findsOneWidget);

    await tester.tap(find.byTooltip('Pause'));
    await tester.pump();
    expect(find.text('Paused'), findsOneWidget);
    await tester.tap(find.text('Resume'));
    await tester.pump();
    expect(find.text('Paused'), findsNothing);
  });
}

Future<void> _pumpUntilFound(WidgetTester tester, Finder finder) async {
  for (var attempt = 0; attempt < 20 && finder.evaluate().isEmpty; attempt++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 250)),
    );
    await tester.pump(const Duration(milliseconds: 16));
  }
}
