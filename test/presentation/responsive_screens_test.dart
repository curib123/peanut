import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:puff_and_crunch/core/theme/app_theme.dart';
import 'package:puff_and_crunch/features/gameplay/presentation/gameplay_screen.dart';
import 'package:puff_and_crunch/features/home/presentation/home_screen.dart';
import 'package:puff_and_crunch/features/level_map/presentation/pre_level_screen.dart';
import 'package:puff_and_crunch/game/presentation/island_match_game.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<void> showScreen(WidgetTester tester, Widget screen, Size size) async {
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));
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
          home: screen,
        ),
      ),
    );
    for (var i = 0; i < 60; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 75)),
      );
      await tester.pump(const Duration(milliseconds: 16));
      if (screen is GameplayScreen) {
        final widgets = find.byWidgetPredicate(
          (widget) => widget is GameWidget,
        );
        if (widgets.evaluate().isNotEmpty) {
          final game =
              tester.widget<GameWidget>(widgets).game as IslandMatchGame;
          if (game.isActive && game.boardComponent.isMounted) break;
        }
      } else if (screen is PreLevelScreen) {
        if (find.text('Start Level').evaluate().isNotEmpty) break;
      } else {
        if (i > 4) break;
      }
    }
  }

  testWidgets('home remains usable on a short landscape screen', (
    tester,
  ) async {
    await showScreen(tester, const HomeScreen(), const Size(844, 390));
    expect(tester.takeException(), isNull);
    await tester.ensureVisible(find.text('Play Adventure'));
    expect(find.text('Play Adventure').hitTestable(), findsOneWidget);
  });

  testWidgets('recipe scrolls on a short landscape screen', (tester) async {
    await showScreen(
      tester,
      const PreLevelScreen(level: 120),
      const Size(844, 390),
    );
    expect(tester.takeException(), isNull);
    await tester.ensureVisible(find.text('Start Level'));
    expect(find.text('Start Level').hitTestable(), findsOneWidget);
  });

  testWidgets('time trial HUD fits a narrow phone with enlarged text', (
    tester,
  ) async {
    await showScreen(
      tester,
      const GameplayScreen(level: 11),
      const Size(320, 640),
    );
    expect(
      find.byWidgetPredicate((widget) => widget is GameWidget),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
    expect(find.text('RECIPE GOALS'), findsOneWidget);
  });

  testWidgets('backgrounding a level pauses the game until explicit resume', (
    tester,
  ) async {
    await showScreen(
      tester,
      const GameplayScreen(level: 12),
      const Size(390, 844),
    );
    final widget = tester.widget<GameWidget>(
      find.byWidgetPredicate((widget) => widget is GameWidget),
    );
    final game = widget.game as IslandMatchGame;
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await tester.pump();
    expect(game.paused, isTrue);
    expect(find.text('Paused'), findsOneWidget);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(game.paused, isTrue);
    await tester.tap(find.text('Resume'));
    await tester.pump();
    expect(game.paused, isFalse);
    expect(tester.takeException(), isNull);
  });
}
