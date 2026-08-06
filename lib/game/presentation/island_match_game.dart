import 'dart:ui';

import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';

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
  }) : _seed = seed,
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
  late final TurnEngine _turnEngine;
  late final LevelSession _session;
  late final BoardComponent boardComponent;
  final TurnInputGate _inputGate = TurnInputGate();
  final ValueNotifier<GameHudState> hud = ValueNotifier(
    const GameHudState(moves: 20, score: 0, status: LevelStatus.playing),
  );

  bool get isInputLocked => _inputGate.isLocked;

  @override
  Color backgroundColor() => const Color(0xFFFFF4D6);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
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
    boardComponent = BoardComponent(board: board);
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
        await boardComponent.animateInvalidSwap(
          first,
          second,
          animationDuration * 0.75,
        );
        return false;
      }
      await boardComponent.animateResolution(
        first,
        second,
        turn.resolution,
        animationDuration,
      );
      hud.value = GameHudState(
        moves: turn.movesRemaining,
        score: turn.score,
        status: turn.status,
      );
      if (turn.status != LevelStatus.playing) {
        onLevelEnded?.call(turn.status, turn.score);
      }
      return true;
    });
    return result ?? false;
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
