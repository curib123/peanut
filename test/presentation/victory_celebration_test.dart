import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:puff_and_crunch/core/theme/app_theme.dart';
import 'package:puff_and_crunch/features/gameplay/presentation/victory_celebration.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<void> showVictory(
    WidgetTester tester, {
    int stars = 2,
    bool reducedMotion = true,
    VoidCallback? onMap,
    VoidCallback? onNext,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.light,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(1.3)),
            child: child!,
          ),
          home: Scaffold(
            body: VictoryCelebration(
              stars: stars,
              score: 8320,
              movesRemaining: 3,
              reducedMotion: reducedMotion,
              onMap: onMap ?? () {},
              onNext: onNext,
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets(
    'result uses earned stars and final score without counting bonus twice',
    (tester) async {
      final semantics = tester.ensureSemantics();
      await showVictory(tester);
      expect(find.bySemanticsLabel('2 of 3 stars earned'), findsOneWidget);
      expect(find.byIcon(Icons.star_rounded), findsNWidgets(2));
      expect(find.byIcon(Icons.star_outline_rounded), findsOneWidget);
      expect(find.text('Score: 8320'), findsOneWidget);
      expect(find.text('Includes 300 unused-move bonus'), findsOneWidget);
      expect(tester.binding.transientCallbackCount, 0);
      semantics.dispose();
    },
  );

  testWidgets(
    'map and next recipe remain reachable on narrow enlarged layout',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 640));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      var next = 0;
      var map = 0;
      await showVictory(tester, onMap: () => map++, onNext: () => next++);
      await tester.ensureVisible(find.text('Next Recipe'));
      await tester.tap(find.text('Next Recipe'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Level Map'));
      await tester.tap(find.text('Level Map'));
      expect(next, 1);
      expect(map, 1);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('celebration finishes and final campaign result offers the map', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(844, 390));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await showVictory(tester, stars: 1, reducedMotion: false);
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    expect(find.text('Next Recipe'), findsNothing);
    expect(find.byIcon(Icons.star_rounded), findsOneWidget);
    await tester.ensureVisible(find.text('Level Map'));
    expect(find.text('Level Map').hitTestable(), findsOneWidget);
    expect(tester.binding.transientCallbackCount, 0);
    expect(tester.takeException(), isNull);
  });
}
