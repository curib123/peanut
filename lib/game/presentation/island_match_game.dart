import 'dart:ui';

import 'package:flame/flame.dart';
import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';
import '../../services/audio/game_audio_service.dart';

import '../domain/match3.dart';
import 'board_component.dart';
import 'turn_input_gate.dart';

class IslandMatchGame extends FlameGame {
  IslandMatchGame({
    Board? initialBoard,
    int seed = 20260806,
    this.animationDuration = 0.18,
    this.onLevelEnded,
    this.level,
    GameAudioService? audio,
    GameHapticsService? haptics,
    this.reducedMotion = false,
  }) : _seed = seed,
       audio = audio ?? GameAudioService.flame(),
       haptics = haptics ?? GameHapticsService(),
       board =
           initialBoard ??
           BoardGenerator(
             seed: level?.seed ?? seed,
             pieceTypes: level?.spawnPool ?? PieceKind.regularValues,
           ).generate(rows: level?.rows ?? 8, columns: level?.columns ?? 8);

  final int _seed;
  final double animationDuration;
  final void Function(LevelStatus status, int score)? onLevelEnded;
  final LevelDefinition? level;
  final Board board;
  final GameAudioService audio;
  final GameHapticsService haptics;
  final bool reducedMotion;
  late final TurnEngine _turnEngine;
  late final LevelSession _session;
  late final BoardComponent boardComponent;
  final TurnInputGate _inputGate = TurnInputGate();
  final ValueNotifier<GameHudState> hud = ValueNotifier(
    const GameHudState(moves: 20, score: 0, status: LevelStatus.playing),
  );
  final ValueNotifier<String?> cascadeMessage = ValueNotifier(null);

  bool get isInputLocked => _inputGate.isLocked;

  @override
  Color backgroundColor() => const Color(0x00000000);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    await Flame.images.loadAll(const [
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
      'effects/match_burst_sheet.png',
    ]);
    _turnEngine = TurnEngine(
      resolver: BoardResolver(seed: _seed + 1),
      shuffler: BoardShuffler(seed: _seed + 2),
    );
    _session = LevelSession(
      turnEngine: _turnEngine,
      board: board,
      moveLimit: level?.moves ?? 20,
      goals: GoalTracker(
        level?.goals.map(GoalState.fromMechanic).toList() ??
            [GoalState(kind: GoalKind.targetScore, target: 5000)],
      ),
      blockers: level == null
          ? null
          : BlockerGrid.fromMechanics(level!.blockers),
      boardObjectives: level == null ? null : _boardObjectives(level!),
      inaccessibleCells: level == null
          ? const {}
          : board.positions
                .where((cell) => !level!.playableCells.contains(cell))
                .toSet(),
    );
    hud.value = GameHudState(
      moves: level?.moves ?? 20,
      score: 0,
      status: LevelStatus.playing,
    );
    boardComponent = BoardComponent(board: board, blockers: _session.blockers);
    add(boardComponent);
    _layout(size);
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    if (isLoaded && boardComponent.isMounted) _layout(size);
  }

  Future<bool> attemptSwap(Position first, Position second) async {
    if (_session.status != LevelStatus.playing) return false;
    final result = await _inputGate.run(() async {
      final turn = _session.play(first, second);
      if (!turn.resolution.isValid) {
        await audio.play('invalid');
        await haptics.tap();
        await boardComponent.animateInvalidSwap(
          first,
          second,
          animationDuration * 0.75,
        );
        return false;
      }
      await audio.play('swap');
      await boardComponent.animateResolution(
        first,
        second,
        turn.resolution,
        animationDuration,
      );
      if (turn.resolution.cascades.length > 1) {
        cascadeMessage.value =
            '${turn.resolution.cascades.length}x Tasty Cascade!';
        Future<void>.delayed(const Duration(milliseconds: 850), () {
          if (cascadeMessage.value != null) cascadeMessage.value = null;
        });
      }
      hud.value = GameHudState(
        moves: turn.movesRemaining,
        score: turn.score,
        status: turn.status,
      );
      if (turn.status != LevelStatus.playing) {
        await audio.play(turn.status == LevelStatus.won ? 'win' : 'lose');
        if (turn.status == LevelStatus.won) await haptics.celebrate();
        onLevelEnded?.call(turn.status, turn.score);
      }
      return true;
    });
    return result ?? false;
  }

  @override
  void onRemove() {
    hud.dispose();
    cascadeMessage.dispose();
    super.onRemove();
  }

  void _layout(Vector2 canvasSize) {
    final availableWidth = canvasSize.x - 24;
    final availableHeight = canvasSize.y - 24;
    final extent = availableWidth < availableHeight
        ? availableWidth
        : availableHeight;
    boardComponent
      ..position = Vector2(
        (canvasSize.x - extent) / 2,
        (canvasSize.y - extent) / 2,
      )
      ..resizeBoard(Vector2.all(extent));
  }
}

BoardObjectives _boardObjectives(LevelDefinition level) {
  Set<Position> cellsFor(String goalId) {
    final cells = <Position>{};
    for (final goal in level.goals.where((goal) => goal.id == goalId)) {
      final raw = goal.parameters['cells'];
      if (raw is! List) continue;
      for (final value in raw) {
        if (value is List &&
            value.length == 2 &&
            value[0] is int &&
            value[1] is int) {
          cells.add(Position(value[0] as int, value[1] as int));
        }
      }
    }
    return cells;
  }

  return BoardObjectives(
    recipeBaskets: cellsFor('drop_recipe_baskets'),
    cream: cellsFor('spread_cream'),
    ovens: cellsFor('light_ovens'),
  );
}

class GameHudState {
  const GameHudState({
    required this.moves,
    required this.score,
    required this.status,
  });

  final int moves;
  final int score;
  final LevelStatus status;
}
