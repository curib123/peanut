import 'package:flame/game.dart';
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

  testWidgets('locked game deep links cannot bypass progression', (
    tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: PuffAndCrunchApp()));
    await tester.pumpAndSettle();
    appRouter.go('/game/120');
    await tester.pumpAndSettle();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 200)),
    );
    await tester.pumpAndSettle();
    expect(find.text('This recipe is still locked'), findsOneWidget);
    expect(
      find.byWidgetPredicate((widget) => widget is GameWidget),
      findsNothing,
    );
    expect(find.text('Back to Journey'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('invalid recipe links offer a recovery action', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: PuffAndCrunchApp()));
    await tester.pumpAndSettle();
    appRouter.go('/level/not-a-recipe');
    await tester.pumpAndSettle();
    expect(find.text('Recipe unavailable'), findsOneWidget);
    expect(find.text('Back to Journey'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
