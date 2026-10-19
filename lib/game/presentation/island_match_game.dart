import 'dart:async';
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
       hud = ValueNotifier(
         GameHudState(
           moves: level?.moves ?? 20,
           score: 0,
           status: LevelStatus.playing,
           timeRemainingSeconds: level?.timeLimitSeconds,
           goals: _goalSnapshots(
             level?.goals.map(GoalState.fromMechanic) ??
                 [GoalState(kind: GoalKind.targetScore, target: 5000)],
           ),
         ),
       ),
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
  final ValueNotifier<GameHudState> hud;
  final ValueNotifier<String?> cascadeMessage = ValueNotifier(null);
  double _timerAccumulator = 0;
  bool _endReported = false;
  bool _ready = false;
  bool _removed = false;
  final Completer<void> _removal = Completer<void>();
  Timer? _cascadeMessageTimer;

  bool get isActive => _ready && !_removed;

  BoardObjectives get boardObjectives => _session.boardObjectives;

  bool get isInputLocked =>
      !isActive ||
      !boardComponent.isMounted ||
      paused ||
      _session.status != LevelStatus.playing ||
      _inputGate.isLocked;

  @override
  Color backgroundColor() => const Color(0x00000000);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    if (_removed) return;
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
      'specials/peanut_kisses.png',
      'effects/match_burst_sheet.png',
    ]);
    if (_removed) return;
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
      timeLimitSeconds: level?.timeLimitSeconds,
    );
    hud.value = GameHudState(
      moves: level?.moves ?? 20,
      score: 0,
      status: LevelStatus.playing,
      timeRemainingSeconds: level?.timeLimitSeconds,
      goals: _goalSnapshots(_session.goals.goals),
    );
    boardComponent = BoardComponent(board: board, blockers: _session.blockers);
    add(boardComponent);
    _layout(size);
    _ready = true;
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    if (isActive && boardComponent.isMounted) _layout(size);
  }

  Future<bool> attemptSwap(Position first, Position second) async {
    if (isInputLocked) return false;
    final result = await _inputGate.run(() async {
      try {
        final turn = _session.play(first, second);
        if (!turn.resolution.isValid) {
          unawaited(audio.play('invalid'));
          unawaited(haptics.tap());
          await _animateWhileActive(
            boardComponent.animateInvalidSwap(
              first,
              second,
              animationDuration * 0.75,
            ),
          );
          return false;
        }
        // Charge the gesture immediately, but reveal a terminal result only
        // after the board has settled and its completion has been reported.
        _publishHud();
        unawaited(audio.play('swap'));
        await _animateWhileActive(
          boardComponent.animateResolution(
            first,
            second,
            turn.resolution,
            animationDuration,
          ),
        );
        if (!isActive) return true;
        if (turn.resolution.cascades.length > 1) {
          cascadeMessage.value =
              '${turn.resolution.cascades.length}x Tasty Cascade!';
          _cascadeMessageTimer?.cancel();
          _cascadeMessageTimer = Timer(const Duration(milliseconds: 850), () {
            if (isActive) cascadeMessage.value = null;
          });
        }
        return true;
      } finally {
        if (isActive) {
          _reportLevelEnd();
          _publishHud();
        }
      }
    });
    return result ?? false;
  }

  @override
  void update(double dt) {
    if (!isActive) return;
    super.update(dt);
    if (paused ||
        _session.status != LevelStatus.playing ||
        _session.timeRemainingSeconds == null) {
      return;
    }
    _timerAccumulator += dt;
    while (_timerAccumulator >= 1 && _session.status == LevelStatus.playing) {
      _timerAccumulator -= 1;
      _session.elapseSecond();
      if (!_inputGate.isLocked) _reportLevelEnd();
      _publishHud();
    }
  }

  void _publishHud() {
    if (!isActive) return;
    hud.value = GameHudState(
      moves: _session.movesRemaining,
      score: _session.score,
      status: _endReported ? _session.status : LevelStatus.playing,
      timeRemainingSeconds: _session.timeRemainingSeconds,
      goals: _goalSnapshots(_session.goals.goals),
    );
  }

  void _reportLevelEnd() {
    final status = _session.status;
    if (_endReported || status == LevelStatus.playing) return;
    _endReported = true;
    if (isActive) {
      unawaited(audio.play(status == LevelStatus.won ? 'win' : 'lose'));
      if (status == LevelStatus.won) unawaited(haptics.celebrate());
    }
    onLevelEnded?.call(status, _session.score);
  }

  Future<void> _animateWhileActive(Future<void> animation) =>
      Future.any([animation, _removal.future]);

  @override
  void onRemove() {
    if (_removed) return;
    _removed = true;
    _removal.complete();
    _cascadeMessageTimer?.cancel();
    // The domain turn is already authoritative even if navigation interrupts
    // its visuals. Preserve an earned result without notifying a disposed HUD.
    if (_ready) _reportLevelEnd();
    hud.dispose();
    cascadeMessage.dispose();
    super.onRemove();
  }

  void _layout(Vector2 canvasSize) {
    final availableWidth = (canvasSize.x - 24).clamp(1.0, double.infinity);
    final availableHeight = (canvasSize.y - 24).clamp(1.0, double.infinity);
    final widthPerCell = availableWidth / board.columns;
    final heightPerCell = availableHeight / board.rows;
    final cell = widthPerCell < heightPerCell ? widthPerCell : heightPerCell;
    final boardSize = Vector2(cell * board.columns, cell * board.rows);
    boardComponent
      ..position = Vector2(
        (canvasSize.x - boardSize.x) / 2,
        (canvasSize.y - boardSize.y) / 2,
      )
      ..resizeBoard(boardSize);
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
    this.timeRemainingSeconds,
    this.goals = const [],
  });

  final int moves;
  final int score;
  final LevelStatus status;
  final int? timeRemainingSeconds;
  final List<GameGoalProgress> goals;
}

class GameGoalProgress {
  const GameGoalProgress({
    required this.kind,
    required this.target,
    required this.progress,
    this.pieceKind,
  });

  final GoalKind kind;
  final int target;
  final int progress;
  final PieceKind? pieceKind;

  bool get isComplete => progress >= target;

  int get remaining => (target - progress).clamp(0, target);
}

List<GameGoalProgress> _goalSnapshots(Iterable<GoalState> goals) =>
    List.unmodifiable([
      for (final goal in goals)
        GameGoalProgress(
          kind: goal.kind,
          target: goal.target,
          progress: goal.progress,
          pieceKind: goal.pieceKind,
        ),
    ]);
