import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:puff_and_crunch/core/theme/app_theme.dart';
import 'package:puff_and_crunch/features/home/presentation/home_screen.dart';
import 'package:puff_and_crunch/features/level_map/presentation/pre_level_screen.dart';
import 'package:puff_and_crunch/features/progress/application/progress_controller.dart';
import 'package:puff_and_crunch/features/progress/data/save_repository.dart';
import 'package:puff_and_crunch/features/progress/domain/game_save_data.dart';
import 'package:puff_and_crunch/services/content/world_presentation_catalog.dart';

void main() {
  testWidgets('home shows saved recipes, stars and the current destination', (
    tester,
  ) async {
    await _show(
      tester,
      const HomeScreen(),
      save: const GameSaveData(
        highestUnlockedLevel: 22,
        starsByLevel: {1: 3, 2: 1, 21: 2, 22: 0, 500: 3},
      ),
    );

    expect(find.text('3 recipes baked'), findsOneWidget);
    expect(find.text('6 stars collected'), findsOneWidget);
    expect(find.text('Peanut Grove'), findsOneWidget);
    expect(find.text('Recipe 22'), findsOneWidget);

    final container = ProviderScope.containerOf(
      tester.element(find.byType(HomeScreen)),
    );
    await container
        .read(progressControllerProvider.notifier)
        .completeLevel(level: 22, score: 4200, stars: 1);
    await tester.pumpAndSettle();

    expect(find.text('4 recipes baked'), findsOneWidget);
    expect(find.text('7 stars collected'), findsOneWidget);
    expect(find.text('Recipe 23'), findsOneWidget);
  });

  testWidgets('finished adventure offers the last recipe without level 121', (
    tester,
  ) async {
    await _show(
      tester,
      const HomeScreen(),
      save: const GameSaveData(highestUnlockedLevel: 121),
    );

    expect(find.text('Adventure complete'), findsOneWidget);
    expect(find.text('Recipe 120'), findsOneWidget);
    expect(find.text('Starlight Bake-Off'), findsOneWidget);
    expect(find.text('Recipe 121'), findsNothing);
  });

  testWidgets('recipe preview shows saved best results and real ingredients', (
    tester,
  ) async {
    await _show(
      tester,
      const PreLevelScreen(level: 1),
      save: const GameSaveData(
        highestUnlockedLevel: 2,
        starsByLevel: {1: 2},
        bestScoreByLevel: {1: 2800},
      ),
    );

    expect(find.text('Reach 1890 points'), findsOneWidget);
    expect(find.text('Best score 2800'), findsOneWidget);
    expect(find.bySemanticsLabel('Best: 2 of 3 stars'), findsOneWidget);
    expect(find.text('27 moves'), findsOneWidget);
    expect(find.text('Difficulty 1'), findsOneWidget);
    expect(find.text('Peanut'), findsOneWidget);
    expect(find.text('Coconut cream'), findsOneWidget);
  });

  for (final size in [const Size(320, 640), const Size(844, 390)]) {
    testWidgets('home actions stay accessible at $size with enlarged text', (
      tester,
    ) async {
      await _show(tester, const HomeScreen(), size: size, textScale: 1.3);

      expect(tester.takeException(), isNull);
      await tester.ensureVisible(find.text('Play Adventure'));
      expect(find.text('Play Adventure').hitTestable(), findsOneWidget);
      final settings = find.byTooltip('Settings');
      expect(settings.hitTestable(), findsOneWidget);
      expect(tester.getSize(settings).shortestSide, greaterThanOrEqualTo(48));
      expect(tester.takeException(), isNull);
    });

    testWidgets('recipe remains readable at $size with enlarged text', (
      tester,
    ) async {
      await _show(
        tester,
        const PreLevelScreen(level: 11),
        size: size,
        textScale: 1.3,
      );

      expect(tester.takeException(), isNull);
      expect(find.text('160s time trial'), findsOneWidget);
      expect(find.text('Start Level').hitTestable(), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}

Future<void> _show(
  WidgetTester tester,
  Widget screen, {
  GameSaveData save = const GameSaveData(),
  Size size = const Size(390, 844),
  double textScale = 1,
}) async {
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.runAsync(WorldPresentationCatalog.load);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        saveRepositoryProvider.overrideWithValue(_SavedProgress(save)),
      ],
      child: MaterialApp(
        theme: AppTheme.light,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        home: screen,
      ),
    ),
  );
  final ready = find.text(
    screen is PreLevelScreen ? 'Start Level' : 'Play Adventure',
  );
  for (var i = 0; i < 240; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 40)),
    );
    await tester.pump(const Duration(milliseconds: 100));
    if (ready.evaluate().isNotEmpty) break;
  }
  expect(
    ready,
    findsOneWidget,
    reason: 'Bundled recipe data did not finish loading in the allotted test window.',
  );
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
