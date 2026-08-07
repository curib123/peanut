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
    await tester.tap(find.text('Play'));
    await tester.pumpAndSettle();
    expect(find.text('Island Recipe Journey'), findsOneWidget);

    await tester.tap(find.byKey(const Key('level-1')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Start Level'));
    await tester.pump(const Duration(seconds: 3));
    await tester.pump();

    expect(find.text('Level 1'), findsWidgets);
    expect(find.text('Moves: 18'), findsOneWidget);
    expect(find.text('Score: 0'), findsOneWidget);
  });
}
