import 'dart:async';

import 'package:flame/game.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:puff_and_crunch/game/domain/match3.dart';
import 'package:puff_and_crunch/game/presentation/island_match_game.dart';
import 'package:puff_and_crunch/services/audio/game_audio_service.dart';

void main() {
  test('input is rejected safely before loading', () async {
    final game = _game();
    addTearDown(game.onRemove);

    expect(game.isInputLocked, isTrue);
    expect(
      await game.attemptSwap(const Position(0, 1), const Position(1, 1)),
      isFalse,
    );
  });

  testWidgets('terminal HUD waits for animation and completion callback', (
    tester,
  ) async {
    final events = <String>[];
    final game = _game(
      target: 1,
      onEnded: (status, score) => events.add('saved:$status'),
    );
    await _mount(tester, game);
    game.hud.addListener(() {
      if (game.hud.value.status != LevelStatus.playing) {
        events.add('hud:${game.hud.value.status}');
      }
    });

    final turn = game.attemptSwap(const Position(0, 1), const Position(1, 1));
    expect(game.hud.value.moves, 9);
    expect(game.hud.value.status, LevelStatus.playing);
    expect(events, isEmpty);

    await _finishTurn(tester, game, turn);
    expect(events, ['saved:${LevelStatus.won}', 'hud:${LevelStatus.won}']);
    expect(game.isInputLocked, isTrue);
  });

  testWidgets('unresponsive sound cannot block animation or level completion', (
    tester,
  ) async {
    final pendingSound = Completer<void>();
    final ended = <LevelStatus>[];
    final game = _game(
      target: 1,
      player: (asset) => asset == 'sfx/swap.wav' || asset == 'sfx/win.wav'
          ? pendingSound.future
          : Future.value(),
      onEnded: (status, score) => ended.add(status),
    );
    await _mount(tester, game);

    final turn = game.attemptSwap(const Position(0, 1), const Position(1, 1));
    try {
      await _finishTurn(tester, game, turn);
      expect(ended, [LevelStatus.won]);
      expect(game.hud.value.status, LevelStatus.won);
    } finally {
      pendingSound.complete();
      await tester.pump();
    }
  });

  testWidgets('timeout during a turn settles once after its animation', (
    tester,
  ) async {
    final ended = <LevelStatus>[];
    final game = _game(
      timeLimit: 10,
      onEnded: (status, score) => ended.add(status),
    );
    await _mount(tester, game);
    game.update(9);
    expect(game.hud.value.timeRemainingSeconds, 1);

    final turn = game.attemptSwap(const Position(0, 1), const Position(1, 1));
    game.update(1);
    expect(game.hud.value.timeRemainingSeconds, 0);
    expect(game.hud.value.status, LevelStatus.playing);
    expect(ended, isEmpty);

    await _finishTurn(tester, game, turn);
    expect(ended, [LevelStatus.lost]);
    expect(game.hud.value.status, LevelStatus.lost);
    game.update(30);
    expect(ended, [LevelStatus.lost]);
  });

  testWidgets('navigation during a winning animation preserves one result', (
    tester,
  ) async {
    final ended = <LevelStatus>[];
    final game = _game(
      target: 1,
      onEnded: (status, score) => ended.add(status),
    );
    await _mount(tester, game);
    final turn = game.attemptSwap(const Position(0, 1), const Position(1, 1));
    var turnCompleted = false;
    turn.then((_) => turnCompleted = true);
    var hudNotifications = 0;
    game.hud.addListener(() => hudNotifications++);

    await tester.pumpWidget(const SizedBox.shrink());
    expect(ended, [LevelStatus.won]);
    expect(game.isInputLocked, isTrue);
    await tester.pump(const Duration(seconds: 3));
    // Completing or cancelling visuals after removal must not publish HUD
    // changes, nor repeat the persisted result.
    expect(turnCompleted, isTrue, reason: 'Removal must release the turn.');
    await turn;
    expect(ended, [LevelStatus.won]);
    expect(hudNotifications, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('cascade banner cleanup is safe after navigation', (
    tester,
  ) async {
    final game = _game(seed: 9);
    await _mount(tester, game);
    final turn = game.attemptSwap(const Position(0, 1), const Position(1, 1));
    await _finishTurn(tester, game, turn);
    expect(game.cascadeMessage.value, isNotNull);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 2));
    expect(tester.takeException(), isNull);
  });

  testWidgets('goal snapshots preserve earlier progress after a turn', (
    tester,
  ) async {
    final game = _game(target: 1);
    await _mount(tester, game);
    final before = game.hud.value;
    expect(before.goals.single.progress, 0);
    expect(before.goals.single.isComplete, isFalse);
    final turn = game.attemptSwap(const Position(0, 1), const Position(1, 1));
    await _finishTurn(tester, game, turn);
    final after = game.hud.value;
    expect(after.goals.single.progress, 1);
    expect(after.goals.single.isComplete, isTrue);
    expect(after.goals.single.remaining, 0);
    expect(before.goals.single.progress, 0);
    expect(() => after.goals.clear(), throwsUnsupportedError);
  });
}

IslandMatchGame _game({
  int seed = 7,
  int target = 999999,
  int? timeLimit,
  SoundPlayer? player,
  void Function(LevelStatus, int)? onEnded,
}) => IslandMatchGame(
  initialBoard: Board([
    for (final row in ['PEP', 'EPC', 'PES', 'SCE'])
      [
        for (final symbol in row.split(''))
          Piece(switch (symbol) {
            'P' => PieceKind.peanut,
            'E' => PieceKind.egg,
            'C' => PieceKind.caramelRibbon,
            _ => PieceKind.sugarCrystal,
          }),
      ],
  ]),
  seed: seed,
  level: LevelDefinition(
    id: 'lifecycle',
    worldId: 'test',
    order: 1,
    rows: 4,
    columns: 3,
    moves: 10,
    timeLimitSeconds: timeLimit,
    seed: seed,
    spawnWeights: {
      PieceKind.peanut: 1,
      PieceKind.egg: 1,
      PieceKind.sugarCrystal: 1,
    },
    starThresholds: const [100, 200, 300],
    goals: [
      MechanicDefinition(id: 'target_score', parameters: {'target': target}),
    ],
  ),
  reducedMotion: true,
  audio: GameAudioService(player: player ?? (_) async {}),
  haptics: GameHapticsService(enabled: false),
  onLevelEnded: onEnded,
);

Future<void> _mount(WidgetTester tester, IslandMatchGame game) async {
  await tester.pumpWidget(
    Directionality(
      textDirection: TextDirection.ltr,
      child: GameWidget(game: game),
    ),
  );
  await tester.runAsync(() async {
    await game.toBeLoaded();
  });
  await tester.pump();
  await tester.runAsync(game.ready);
  await tester.pump();
}

Future<void> _finishTurn(
  WidgetTester tester,
  IslandMatchGame game,
  Future<bool> turn,
) async {
  var completed = false;
  turn.then((_) => completed = true);
  for (var frame = 0; frame < 240 && !completed; frame++) {
    await tester.pump(const Duration(milliseconds: 16));
  }
  expect(
    completed,
    isTrue,
    reason: 'Turn must finish without waiting for audio.',
  );
  expect(await turn, isTrue);
}
