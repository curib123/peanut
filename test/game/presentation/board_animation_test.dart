import 'package:flame/game.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:puff_and_crunch/game/domain/match3.dart';
import 'package:puff_and_crunch/game/presentation/island_match_game.dart';
import 'package:puff_and_crunch/services/audio/game_audio_service.dart';

IslandMatchGame createGame() => IslandMatchGame(
  initialBoard: Board([
    for (final row in ['PEP', 'EPC', 'PES', 'SCE'])
      [
        for (final c in row.split(''))
          Piece(switch (c) {
            'P' => PieceKind.peanut,
            'E' => PieceKind.egg,
            'C' => PieceKind.caramelRibbon,
            _ => PieceKind.sugarCrystal,
          }),
      ],
  ]),
  animationDuration: .04,
  reducedMotion: true,
  audio: GameAudioService(player: (_) async {}),
  haptics: GameHapticsService(enabled: false),
);

Future<void> mountGame(WidgetTester tester, IslandMatchGame game) async {
  await tester.pumpWidget(
    Directionality(
      textDirection: TextDirection.ltr,
      child: GameWidget(game: game),
    ),
  );
  await tester.runAsync(() async => await game.toBeLoaded());
  await tester.pump();
  await tester.runAsync(game.ready);
  await tester.pump();
}

void main() {
  testWidgets('rectangular boards stay within the playable viewport', (
    tester,
  ) async {
    final game = createGame();
    await mountGame(tester, game);
    final board = game.boardComponent;
    expect(board.size.x / board.cellExtent, 3);
    expect(board.size.y / board.cellExtent, 4);
    expect(board.position.x + board.size.x, lessThanOrEqualTo(game.size.x));
    expect(board.position.y + board.size.y, lessThanOrEqualTo(game.size.y));
  });

  testWidgets('resizing during a cascade preserves completion and input', (
    tester,
  ) async {
    final game = createGame();
    await mountGame(tester, game);
    var complete = false;
    final turn = game.attemptSwap(const Position(0, 1), const Position(1, 1));
    turn.then((_) => complete = true);
    await tester.pump(const Duration(milliseconds: 16));
    game.onGameResize(Vector2(390, 500));
    for (var frame = 0; frame < 240 && !complete; frame++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    expect(complete, isTrue);
    expect(await turn, isTrue);
    expect(game.isInputLocked, isFalse);
    expect(game.boardComponent.size.y, lessThanOrEqualTo(500));
    expect(tester.takeException(), isNull);
  });
}
