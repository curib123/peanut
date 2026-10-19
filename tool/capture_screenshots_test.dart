import 'dart:io';

import 'package:flame/flame.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:puff_and_crunch/app/app.dart';
import 'package:puff_and_crunch/app/router.dart';
import 'package:puff_and_crunch/core/theme/app_theme.dart';
import 'package:puff_and_crunch/features/gameplay/presentation/gameplay_screen.dart';
import 'package:puff_and_crunch/game/domain/match3.dart';
import 'package:puff_and_crunch/game/presentation/island_match_game.dart';
import 'package:puff_and_crunch/services/audio/game_audio_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    // ignore: invalid_use_of_visible_for_testing_member
    SharedPreferences.setMockInitialValues({});
    appRouter.go('/');
  });

  testWidgets('capture phone-sized game tour', (tester) async {
    await _loadFonts();
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const ProviderScope(child: PuffAndCrunchApp()));
    await tester.pumpAndSettle();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(seconds: 1)),
    );
    await tester.pump();
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('../docs/screenshots/01-home.png'),
    );

    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('../docs/screenshots/02-settings.png'),
    );

    appRouter.go('/map');
    for (var frame = 0; frame < 30; frame++) {
      await tester.pump(const Duration(milliseconds: 50));
      if (find.byKey(const Key('level-1')).evaluate().isNotEmpty) break;
    }
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(seconds: 1)),
    );
    await tester.pump(const Duration(seconds: 1));
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('../docs/screenshots/03-level-map.png'),
    );

    await tester.scrollUntilVisible(
      find.text('A secret world is hidden above'),
      650,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pump(const Duration(milliseconds: 500));
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('../docs/screenshots/12-secret-world-cloud.png'),
    );
    await tester.scrollUntilVisible(
      find.byKey(const Key('level-1')),
      -650,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.byKey(const Key('level-1')));
    await tester.pumpAndSettle();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(seconds: 1)),
    );
    await tester.pump();
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('../docs/screenshots/04-pre-level.png'),
    );

    await tester.runAsync(_preloadGameSprites);
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          home: GameplayScreen(level: 1),
        ),
      ),
    );
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(seconds: 4)),
    );
    for (var frame = 0; frame < 120; frame++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    expect(find.text('Moves: 27'), findsOneWidget);
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('../docs/screenshots/05-gameplay.png'),
    );

    tester
        .widget<IconButton>(
          find.widgetWithIcon(IconButton, Icons.pause_rounded),
        )
        .onPressed!();
    await tester.pump();
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('../docs/screenshots/06-paused.png'),
    );

    tester
        .widget<IconButton>(
          find.widgetWithIcon(IconButton, Icons.pause_rounded),
        )
        .onPressed!();
    await tester.pump();
    final gameWidget = tester.widget<GameWidget>(
      find.byWidgetPredicate((widget) => widget is GameWidget),
    );
    final game = gameWidget.game as IslandMatchGame;
    game.hud.value = const GameHudState(
      moves: 6,
      score: 11200,
      status: LevelStatus.won,
    );
    for (var frame = 0; frame < 60; frame++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('../docs/screenshots/07-victory.png'),
    );

    game.hud.value = const GameHudState(
      moves: 0,
      score: 2400,
      status: LevelStatus.lost,
    );
    await tester.pump(const Duration(milliseconds: 300));
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('../docs/screenshots/08-failure.png'),
    );

    await _pumpGameplay(tester, level: 10);
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('../docs/screenshots/09-blockers.png'),
    );

    await _pumpGameplay(tester, level: 61);
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('../docs/screenshots/10-sugar-harbor.png'),
    );

    final showcase = await _pumpSpecialShowcase(tester);
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('../docs/screenshots/11-special-pieces.png'),
    );
    var settled = false;
    final powerTurn = showcase.attemptSwap(
      const Position(0, 0),
      const Position(0, 1),
    );
    powerTurn.then((_) => settled = true);
    for (var frame = 0; frame < 16; frame++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('../docs/screenshots/13-power-activation.png'),
    );
    for (var frame = 0; frame < 400 && !settled; frame++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    expect(settled, isTrue);
    expect(await powerTurn, isTrue);
    await _pumpGameplay(tester, level: 41);
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('../docs/screenshots/14-basket-goals.png'),
    );
    await _pumpGameplay(tester, level: 120);
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('../docs/screenshots/15-time-trial.png'),
    );
    await tester.binding.setSurfaceSize(const Size(844, 390));
    await _pumpGameplay(tester, level: 11);
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('../docs/screenshots/16-landscape-gameplay.png'),
    );
  });
}

Future<IslandMatchGame> _pumpSpecialShowcase(WidgetTester tester) async {
  final board =
      Board([
          for (var row = 0; row < 6; row++)
            [
              for (var column = 0; column < 6; column++)
                Piece(PieceKind.regularValues[(row * 2 + column) % 6]),
            ],
        ])
        ..setPiece(
          const Position(0, 0),
          const Piece(
            PieceKind.peanut,
            specialKind: SpecialKind.sugarBeam,
            beamOrientation: BeamOrientation.horizontal,
          ),
        )
        ..setPiece(
          const Position(0, 1),
          const Piece(
            PieceKind.egg,
            specialKind: SpecialKind.goldenRecipeSpark,
          ),
        )
        ..setPiece(
          const Position(0, 2),
          const Piece(
            PieceKind.sugarCrystal,
            specialKind: SpecialKind.ovenBurst,
          ),
        )
        ..setPiece(
          const Position(0, 3),
          const Piece(
            PieceKind.caramelRibbon,
            specialKind: SpecialKind.peanutSpinner,
          ),
        )
        ..setPiece(
          const Position(0, 4),
          const Piece(PieceKind.peanut, specialKind: SpecialKind.peanutKisses),
        );
  final game = IslandMatchGame(
    initialBoard: board,
    reducedMotion: false,
    audio: GameAudioService(player: (_) async {}),
    haptics: GameHapticsService(enabled: false),
  );
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: Scaffold(
        appBar: AppBar(title: const Text('Special Recipe Pieces')),
        body: DecoratedBox(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/images/worlds/festival_oven.webp'),
              fit: BoxFit.cover,
            ),
          ),
          child: GameWidget(game: game),
        ),
      ),
    ),
  );
  await tester.runAsync(() => Future<void>.delayed(const Duration(seconds: 2)));
  for (var frame = 0; frame < 60; frame++) {
    await tester.pump(const Duration(milliseconds: 16));
  }
  return game;
}

Future<void> _pumpGameplay(WidgetTester tester, {required int level}) async {
  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: GameplayScreen(key: ValueKey('capture-$level'), level: level),
      ),
    ),
  );
  await tester.pump();
  await tester.runAsync(() => Future<void>.delayed(const Duration(seconds: 3)));
  for (var frame = 0; frame < 90; frame++) {
    await tester.pump(const Duration(milliseconds: 16));
  }
}

Future<void> _preloadGameSprites() => Flame.images.loadAll(const [
  'pieces/peanut.png',
  'pieces/egg.png',
  'pieces/sugar_crystal.png',
  'pieces/caramel_ribbon.png',
  'pieces/coconut_cream.png',
  'pieces/cocoa_crumb.png',
  'specials/sugar_beam_horizontal.png',
  'specials/sugar_beam_vertical.png',
  'specials/golden_recipe_spark.png',
  'specials/oven_burst.png',
  'specials/peanut_spinner.png',
  'specials/peanut_kisses.png',
  'effects/match_burst_sheet.png',
  'blockers/sugar_frosting.png',
  'blockers/peanut_crate.png',
  'blockers/sticky_caramel.png',
  'blockers/chocolate_crumbs.png',
  'blockers/oven_stone.png',
  'blockers/bakers_twine.png',
]);

Future<void> _loadFonts() async {
  const materialPath = r'C:\src\flutter\bin\cache\artifacts\material_fonts\';
  final roboto = FontLoader('Roboto');
  for (final name in [
    'roboto-regular.ttf',
    'roboto-medium.ttf',
    'roboto-bold.ttf',
    'roboto-black.ttf',
  ]) {
    final bytes = File('$materialPath$name').readAsBytesSync();
    roboto.addFont(
      Future.value(ByteData.view(Uint8List.fromList(bytes).buffer)),
    );
  }
  final iconBytes = File(
    '${materialPath}materialicons-regular.otf',
  ).readAsBytesSync();
  final icons = FontLoader(
    'MaterialIcons',
  )..addFont(Future.value(ByteData.view(Uint8List.fromList(iconBytes).buffer)));
  await Future.wait([roboto.load(), icons.load()]);
}
