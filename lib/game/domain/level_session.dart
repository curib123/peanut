import 'blockers.dart';
import 'board.dart';
import 'objectives.dart';
import 'piece.dart';
import 'position.dart';
import 'turn_engine.dart';

enum LevelStatus { playing, won, lost }

class LevelTurnResult {
  LevelTurnResult({
    required this.resolution,
    required this.progress,
    required this.movesRemaining,
    required this.score,
    required this.status,
    this.chocolateSpread,
  });

  final TurnResolution resolution;
  final TurnProgress progress;
  final int movesRemaining;
  final int score;
  final LevelStatus status;
  final Position? chocolateSpread;
}

class LevelSession {
  LevelSession({
    required this.turnEngine,
    required this.board,
    required int moveLimit,
    required this.goals,
    BlockerGrid? blockers,
    BoardObjectives? boardObjectives,
    Set<Position> inaccessibleCells = const {},
    int? timeLimitSeconds,
  }) : assert(moveLimit > 0),
       movesRemaining = moveLimit,
       timeRemainingSeconds = timeLimitSeconds,
       blockers = blockers ?? BlockerGrid(),
       inaccessibleCells = Set.unmodifiable(inaccessibleCells),
       boardObjectives = boardObjectives ?? BoardObjectives() {
    for (final position in this.blockers.blockingPositions) {
      if (board.contains(position)) board.setPiece(position, null);
    }
    for (final position in this.inaccessibleCells) {
      if (board.contains(position)) board.setPiece(position, null);
    }
  }

  final TurnEngine turnEngine;
  final Board board;
  final GoalTracker goals;
  final BlockerGrid blockers;
  final Set<Position> inaccessibleCells;
  final BoardObjectives boardObjectives;
  int movesRemaining;
  int? timeRemainingSeconds;
  int score = 0;
  LevelStatus status = LevelStatus.playing;

  bool elapseSecond() {
    final remaining = timeRemainingSeconds;
    if (status != LevelStatus.playing || remaining == null) return false;
    timeRemainingSeconds = remaining - 1;
    if (timeRemainingSeconds == 0) status = LevelStatus.lost;
    return true;
  }

  LevelTurnResult play(Position first, Position second) {
    if (status != LevelStatus.playing) {
      throw StateError('The level has already ended.');
    }
    if (blockers.locksSwap(first) ||
        inaccessibleCells.contains(first) ||
        inaccessibleCells.contains(second) ||
        blockers.locksSwap(second) ||
        blockers.blocksCell(first) ||
        blockers.blocksCell(second)) {
      return _invalid();
    }

    final resolution = turnEngine.resolveSwap(
      board,
      first,
      second,
      blockedCells: {...blockers.blockingPositions, ...inaccessibleCells},
    );
    if (!resolution.isValid) {
      return LevelTurnResult(
        resolution: resolution,
        progress: TurnProgress(),
        movesRemaining: movesRemaining,
        score: score,
        status: status,
      );
    }

    movesRemaining--;
    var turnScore = 0;
    var creamSpread = 0;
    var ovensLit = 0;
    final collected = <PieceKind, int>{};
    final removedBlockers = <BlockerKind, int>{};

    for (var index = 0; index < resolution.cascades.length; index++) {
      final frame = resolution.cascades[index];
      turnScore += frame.matched.length * 60 * (index + 1);
      turnScore += frame.activatedSpecials.length * 250;
      for (final position in frame.matched) {
        final piece = frame.beforeClear.pieceAt(position);
        if (piece != null) {
          collected.update(piece.kind, (count) => count + 1, ifAbsent: () => 1);
        }
      }
      final impact = blockers.resolveClear(
        frame.beforeClear,
        frame.matched,
        isSpecialClear: frame.activatedSpecials.isNotEmpty,
      );
      for (final entry in impact.removed.entries) {
        removedBlockers.update(
          entry.key,
          (count) => count + entry.value,
          ifAbsent: () => entry.value,
        );
      }
      final objectiveImpact = boardObjectives.resolveClear(frame.matched);
      creamSpread += objectiveImpact.creamSpread;
      ovensLit += objectiveImpact.ovensLit;
    }

    final droppedBaskets = boardObjectives.settleBaskets(
      rows: board.rows,
      blockers: blockers,
    );
    final chocolateSpread = blockers.endTurnChocolateSpread(board);
    score += turnScore;
    final progress = TurnProgress(
      score: turnScore,
      collected: collected,
      removedBlockers: removedBlockers,
      droppedBaskets: droppedBaskets,
      spreadCream: creamSpread,
      litOvens: ovensLit,
    );
    goals.apply(progress);
    if (goals.isComplete) {
      status = LevelStatus.won;
      // Bank unused moves only after the goals are complete. This keeps the
      // deterministic domain score authoritative while the UI animates it.
      score += movesRemaining * 100;
    } else if (movesRemaining == 0) {
      status = LevelStatus.lost;
    }

    return LevelTurnResult(
      resolution: resolution,
      progress: progress,
      movesRemaining: movesRemaining,
      score: score,
      status: status,
      chocolateSpread: chocolateSpread,
    );
  }

  LevelTurnResult _invalid() {
    final resolution = TurnResolution.invalid(board: board);
    return LevelTurnResult(
      resolution: resolution,
      progress: TurnProgress(),
      movesRemaining: movesRemaining,
      score: score,
      status: status,
    );
  }
}
