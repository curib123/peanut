import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:puff_and_crunch/core/theme/app_theme.dart';
import 'package:puff_and_crunch/features/level_map/presentation/level_map_screen.dart';
import 'package:puff_and_crunch/features/progress/application/progress_controller.dart';
import 'package:puff_and_crunch/features/progress/data/save_repository.dart';
import 'package:puff_and_crunch/features/progress/domain/game_save_data.dart';
import 'package:puff_and_crunch/services/content/world_presentation_catalog.dart';

void main() {
  testWidgets('advanced progress opens at the current unlocked level', (
    tester,
  ) async {
    await _showMap(tester, highestLevel: 85);

    expect(find.byKey(const Key('level-85')).hitTestable(), findsOneWidget);
    expect(_background('festival_oven'), findsOneWidget);
  });

  testWidgets('current level action returns after exploring the map', (
    tester,
  ) async {
    await _showMap(tester, highestLevel: 85);
    await tester.drag(find.byType(ListView), const Offset(0, -2400));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('level-85')).hitTestable(), findsNothing);

    await tester.tap(find.byTooltip('Current level'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('level-85')).hitTestable(), findsOneWidget);
    expect(_background('festival_oven'), findsOneWidget);
  });

  testWidgets('completed adventure returns to level 120', (tester) async {
    await _showMap(tester, highestLevel: 121);

    expect(find.byKey(const Key('level-120')).hitTestable(), findsOneWidget);
    expect(find.text('GO'), findsOneWidget);
    expect(_background('starlight_bake_off'), findsOneWidget);
  });

  testWidgets('returning from a recipe restores newly unlocked progress', (
    tester,
  ) async {
    final router = GoRouter(
      initialLocation: '/map',
      routes: [
        GoRoute(path: '/map', builder: (_, _) => const LevelMapScreen()),
        GoRoute(
          path: '/level/:level',
          builder: (_, _) => const Scaffold(body: Text('Recipe detail')),
        ),
      ],
    );
    addTearDown(router.dispose);
    await _showMap(tester, highestLevel: 85, router: router);
    final container = ProviderScope.containerOf(
      tester.element(find.byType(LevelMapScreen)),
    );
    final scrollable = tester.state<ScrollableState>(
      find.descendant(
        of: find.byType(ListView),
        matching: find.byType(Scrollable),
      ),
    );
    scrollable.position.jumpTo(0);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('level-1')));
    await tester.pumpAndSettle();
    expect(find.text('Recipe detail'), findsOneWidget);

    await container
        .read(progressControllerProvider.notifier)
        .completeLevel(level: 85, score: 3000, stars: 1);
    router.pop();
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('level-86')).hitTestable(), findsOneWidget);
  });

  testWidgets('world title fits a narrow phone with enlarged text', (
    tester,
  ) async {
    await _showMap(
      tester,
      highestLevel: 101,
      size: const Size(320, 640),
      textScale: 2,
    );

    expect(find.textContaining('Starlight Bake-Off'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('map title remains white over world artwork', (tester) async {
    await _showMap(tester, highestLevel: 1);

    final title = tester.element(find.text('Island Recipe Journey'));
    expect(DefaultTextStyle.of(title).style.color, Colors.white);
    expect(find.byKey(const Key('level-1')).hitTestable(), findsOneWidget);
    expect(find.byKey(const Key('level-2')).hitTestable(), findsOneWidget);
  });
}

Finder _background(String world) => find.byWidgetPredicate((widget) {
  if (widget is! Image || widget.image is! AssetImage) return false;
  return (widget.image as AssetImage).assetName ==
      'assets/images/worlds/$world.webp';
});

Future<void> _showMap(
  WidgetTester tester, {
  required int highestLevel,
  Size size = const Size(390, 844),
  double textScale = 1,
  GoRouter? router,
}) async {
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.runAsync(WorldPresentationCatalog.load);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        saveRepositoryProvider.overrideWithValue(
          _SavedProgress(
            GameSaveData(
              highestUnlockedLevel: highestLevel,
              settings: const GameSettings(reducedMotion: true),
            ),
          ),
        ),
      ],
      child: router == null
          ? MaterialApp(
              theme: AppTheme.light,
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(textScaler: TextScaler.linear(textScale)),
                child: child!,
              ),
              home: const LevelMapScreen(),
            )
          : MaterialApp.router(theme: AppTheme.light, routerConfig: router),
    ),
  );
  await tester.pump();
  await tester.pumpAndSettle();
}

class _SavedProgress implements SaveRepository {
  _SavedProgress(this.data);
  GameSaveData data;

  @override
  Future<GameSaveData> load() async => data;

  @override
  Future<void> save(GameSaveData value) async => data = value;

  @override
  Future<void> clear() async => data = const GameSaveData();
}
