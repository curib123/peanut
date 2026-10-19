import 'package:flutter_test/flutter_test.dart';
import 'package:puff_and_crunch/game/domain/match3.dart';

void main() {
  test('one swap costs one move even when it creates cascades', () {
    final board = boardFrom(['PEP', 'EPC', 'PES', 'SCE']);
    final session = LevelSession(
      turnEngine: TurnEngine(
        resolver: BoardResolver(seed: 7),
        shuffler: BoardShuffler(seed: 8),
      ),
      board: board,
      moveLimit: 10,
      goals: GoalTracker([
        GoalState(kind: GoalKind.targetScore, target: 999999),
      ]),
    );
    final result = session.play(const Position(0, 1), const Position(1, 1));
    expect(result.resolution.isValid, isTrue);
    expect(result.movesRemaining, 9);
  });

  test('time trial expires independently without consuming moves', () {
    final session = makeSession(
      moveLimit: 10,
      timeLimitSeconds: 2,
      goals: GoalTracker([
        GoalState(kind: GoalKind.targetScore, target: 999999),
      ]),
    );
    expect(session.elapseSecond(), isTrue);
    expect(session.movesRemaining, 10);
    expect(session.status, LevelStatus.playing);
    expect(session.elapseSecond(), isTrue);
    expect(session.movesRemaining, 10);
    expect(session.status, LevelStatus.lost);
  });
  test('all seven goal types consume their matching progress only', () {
    final goals = GoalTracker([
      GoalState(kind: GoalKind.targetScore, target: 100),
      GoalState(
        kind: GoalKind.collectPieces,
        target: 2,
        pieceKind: PieceKind.egg,
      ),
      GoalState(kind: GoalKind.clearFrosting, target: 1),
      GoalState(kind: GoalKind.breakCrates, target: 1),
      GoalState(kind: GoalKind.dropRecipeBaskets, target: 1),
      GoalState(kind: GoalKind.spreadCream, target: 2),
      GoalState(kind: GoalKind.lightOvens, target: 1),
    ]);

    goals.apply(
      TurnProgress(
        score: 120,
        collected: {PieceKind.egg: 2, PieceKind.peanut: 20},
        removedBlockers: {
          BlockerKind.sugarFrosting: 1,
          BlockerKind.peanutCrate: 1,
        },
        droppedBaskets: 1,
        spreadCream: 2,
        litOvens: 1,
      ),
    );

    expect(goals.isComplete, isTrue);
    expect(goals.goals.every((goal) => goal.progress == goal.target), isTrue);
  });

  test('goal definitions are data-driven and reject unknown handlers', () {
    final goal = GoalState.fromMechanic(
      MechanicDefinition(
        id: 'collect_pieces',
        parameters: {'pieceId': 'mango_macaron', 'count': 7},
      ),
    );

    expect(goal.pieceKind, const PieceKind('mango_macaron'));
    expect(goal.target, 7);
    expect(
      () => GoalState.fromMechanic(MechanicDefinition(id: 'unknown_goal')),
      throwsA(isA<ContentException>()),
    );
  });

  test('cream spreads, ovens light, and baskets drop around blockers', () {
    final objectives = BoardObjectives(
      recipeBaskets: {const Position(0, 0), const Position(0, 1)},
      cream: {const Position(2, 2)},
      ovens: {const Position(3, 3)},
    );
    final blockers = BlockerGrid({
      const Position(2, 1): const BlockerState(BlockerKind.ovenStone),
    });

    final impact = objectives.resolveClear({
      const Position(2, 2),
      const Position(3, 2),
    });
    final dropped = objectives.settleBaskets(
      rows: 4,
      blockers: blockers,
      clearedCells: {
        const Position(1, 0),
        const Position(2, 0),
        const Position(3, 0),
        const Position(1, 1),
        const Position(3, 1),
      },
    );

    expect(impact.creamSpread, 1);
    expect(impact.ovensLit, 1);
    expect(dropped, 1);
    expect(objectives.recipeBaskets, contains(const Position(1, 1)));
  });

  group('level outcome', () {
    test('victory occurs immediately when all goals complete', () {
      final session = makeSession(
        moveLimit: 3,
        goals: GoalTracker([GoalState(kind: GoalKind.targetScore, target: 1)]),
      );

      final result = session.play(const Position(0, 1), const Position(1, 1));

      expect(result.status, LevelStatus.won);
      expect(result.movesRemaining, 2);
      expect(result.score, result.progress.score + 200);
    });

    test('failure occurs when the last move ends with incomplete goals', () {
      final session = makeSession(
        moveLimit: 1,
        goals: GoalTracker([
          GoalState(kind: GoalKind.targetScore, target: 1000000),
        ]),
      );

      final result = session.play(const Position(0, 1), const Position(1, 1));

      expect(result.status, LevelStatus.lost);
      expect(result.movesRemaining, 0);
    });

    test('invalid or blocker-locked swaps do not consume moves', () {
      final session = makeSession(
        moveLimit: 2,
        goals: GoalTracker([
          GoalState(kind: GoalKind.targetScore, target: 9999),
        ]),
        blockers: BlockerGrid({
          const Position(0, 1): const BlockerState(BlockerKind.bakersTwine),
        }),
      );

      final result = session.play(const Position(0, 1), const Position(1, 1));

      expect(result.resolution.isValid, isFalse);
      expect(result.movesRemaining, 2);
      expect(result.status, LevelStatus.playing);
    });
  });
}

LevelSession makeSession({
  required int moveLimit,
  required GoalTracker goals,
  BlockerGrid? blockers,
  int? timeLimitSeconds,
}) {
  final board = boardFrom(['PEP', 'EPC', 'PES', 'SCE']);
  return LevelSession(
    turnEngine: TurnEngine(
      resolver: BoardResolver(seed: 81),
      shuffler: BoardShuffler(seed: 82),
    ),
    board: board,
    moveLimit: moveLimit,
    goals: goals,
    blockers: blockers,
    timeLimitSeconds: timeLimitSeconds,
  );
}

Board boardFrom(List<String> rows) => Board([
  for (final row in rows) [for (final symbol in row.split('')) piece(symbol)],
]);

Piece piece(String symbol) => Piece(switch (symbol) {
  'P' => PieceKind.peanut,
  'E' => PieceKind.egg,
  'S' => PieceKind.sugarCrystal,
  'C' => PieceKind.caramelRibbon,
  _ => throw ArgumentError.value(symbol),
});
