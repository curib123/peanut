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

  testWidgets('launch-to-gameplay flow works across app boundaries', (
    tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: PuffAndCrunchApp()));
    await tester.pumpAndSettle();

    expect(find.text('Puff & Crunch'), findsOneWidget);
    await tester.tap(find.text('Play Adventure'));
    for (var frame = 0; frame < 30; frame++) {
      await tester.pump(const Duration(milliseconds: 50));
      if (find.text('Island Recipe Journey').evaluate().isNotEmpty) break;
    }
    expect(find.text('Island Recipe Journey'), findsOneWidget);

    await tester.tap(find.byKey(const Key('level-1')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Start Level'));
    await tester.pump();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(seconds: 3)),
    );
    for (var frame = 0; frame < 90; frame++) {
      await tester.pump(const Duration(milliseconds: 16));
    }

    expect(find.text('Level 1'), findsWidgets);
    expect(find.text('Moves: 27'), findsOneWidget);
    expect(find.text('Score: 0'), findsOneWidget);
  });
}
