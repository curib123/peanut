import 'package:flutter_test/flutter_test.dart' hide MatchFinder;
import 'package:puff_and_crunch/game/domain/match3.dart';
import 'package:puff_and_crunch/services/content/bundled_level_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('a crate destroyed by a beam refills in the same cascade', () {
    const crate = Position(3, 4);
    final board = BoardGenerator(seed: 17).generate()
      ..setPiece(
        const Position(3, 2),
        const Piece(
          PieceKind.peanut,
          specialKind: SpecialKind.sugarBeam,
          beamOrientation: BeamOrientation.horizontal,
        ),
      );
    final session = LevelSession(
      board: board,
      moveLimit: 10,
      goals: GoalTracker([
        GoalState(kind: GoalKind.targetScore, target: 999999),
      ]),
      blockers: BlockerGrid({
        crate: const BlockerState(BlockerKind.peanutCrate),
      }),
      turnEngine: TurnEngine(
        resolver: BoardResolver(seed: 18),
        shuffler: BoardShuffler(seed: 19),
      ),
    );

    final turn = session.play(const Position(3, 2), const Position(3, 3));

    expect(turn.progress.removedBlockers[BlockerKind.peanutCrate], 1);
    expect(session.blockers.at(crate), isNull);
    expect(
      turn.resolution.cascades.first.afterRefill.pieceAt(crate),
      isNotNull,
    );
    expect(session.board.pieceAt(crate), isNotNull);
    expect(const MatchFinder().find(board), isEmpty);
  });

  test('an unrelated clear cannot win shipped basket level 41', () async {
    final level = await const BundledLevelRepository().load(41);
    final session = sessionFor(level);
    final turn = session.play(const Position(5, 5), const Position(5, 6));

    expect(turn.resolution.isValid, isTrue);
    expect(
      turn.resolution.cascades
          .expand((frame) => frame.matched)
          .every((position) => position.column == 6),
      isTrue,
    );
    expect(turn.progress.droppedBaskets, 0);
    expect(session.boardObjectives.recipeBaskets, {
      const Position(0, 2),
      const Position(0, 5),
    });
    expect(turn.status, LevelStatus.playing);
  });

  test('baskets descend only through support removed in each clear', () async {
    final level = await const BundledLevelRepository().load(41);
    final session = sessionFor(
      level,
      objectives: BoardObjectives(recipeBaskets: {const Position(0, 6)}),
    );

    final turn = session.play(const Position(5, 5), const Position(5, 6));

    expect(turn.progress.droppedBaskets, 0);
    expect(session.boardObjectives.recipeBaskets, {const Position(3, 6)});
  });

  test('a locked-only opening is shuffled into a legal playable board', () {
    final board = BoardGenerator(seed: 0).generate(rows: 3, columns: 3);
    const locked = Position(1, 0);
    final lockedPiece = board.pieceAt(locked);
    expect(const MoveValidator().hasValidMove(board), isTrue);
    final session = LevelSession(
      board: board,
      moveLimit: 10,
      goals: GoalTracker([
        GoalState(kind: GoalKind.targetScore, target: 999999),
      ]),
      blockers: BlockerGrid({
        locked: const BlockerState(BlockerKind.bakersTwine),
      }),
      turnEngine: TurnEngine(
        resolver: BoardResolver(seed: 1),
        shuffler: BoardShuffler(seed: 2),
      ),
    );

    expect(legalMoves(session), isNotEmpty);
    expect(board.pieceAt(locked), lockedPiece);
    expect(const MatchFinder().find(board), isEmpty);
  });

  test('locked specials do not count as available moves', () {
    final board = BoardGenerator(seed: 0).generate(rows: 3, columns: 3)
      ..setPiece(
        const Position(1, 0),
        const Piece(PieceKind.egg, specialKind: SpecialKind.ovenBurst),
      );
    expect(const MoveValidator().hasValidMove(board), isTrue);
    expect(
      const MoveValidator().hasValidMove(
        board,
        unavailableCells: {const Position(1, 0)},
      ),
      isFalse,
    );
  });

  test('baskets do not pass through inaccessible tray cells', () {
    final objectives = BoardObjectives(recipeBaskets: {const Position(0, 0)});
    final dropped = objectives.settleBaskets(
      rows: 4,
      blockers: BlockerGrid(),
      inaccessibleCells: {const Position(2, 0)},
      clearedCells: {const Position(1, 0), const Position(3, 0)},
    );
    expect(dropped, 0);
    expect(objectives.recipeBaskets, {const Position(1, 0)});
  });

  test(
    'a basket is collected only after cleared support takes it to the exit',
    () {
      final objectives = BoardObjectives(recipeBaskets: {const Position(0, 0)});
      final blockers = BlockerGrid();
      expect(objectives.settleBaskets(rows: 4, blockers: blockers), 0);
      expect(objectives.recipeBaskets, {const Position(0, 0)});
      expect(
        objectives.settleBaskets(
          rows: 4,
          blockers: blockers,
          clearedCells: {const Position(3, 0)},
        ),
        0,
      );
      expect(objectives.recipeBaskets, {const Position(1, 0)});
      expect(
        objectives.settleBaskets(
          rows: 4,
          blockers: blockers,
          clearedCells: {const Position(2, 0), const Position(3, 0)},
        ),
        1,
      );
      expect(objectives.recipeBaskets, isEmpty);
    },
  );

  test(
    'all campaign sessions stay stable, playable and reach a terminal result',
    () async {
      final levels = await const BundledLevelRepository().loadLaunchLevels();
      for (final level in levels) {
        final session = sessionFor(level);
        for (
          var turnIndex = 0;
          session.status == LevelStatus.playing;
          turnIndex++
        ) {
          final moves = legalMoves(session);
          expect(moves, isNotEmpty, reason: '${level.id} turn $turnIndex');
          final move = moves[(level.order + turnIndex * 7) % moves.length];
          final beforeMoves = session.movesRemaining;
          final result = session.play(move.$1, move.$2);
          expect(result.resolution.isValid, isTrue, reason: level.id);
          expect(session.movesRemaining, beforeMoves - 1, reason: level.id);
          expect(
            const MatchFinder().find(session.board),
            isEmpty,
            reason: level.id,
          );
          for (final cell in session.board.positions) {
            final blocked =
                session.blockers.blocksCell(cell) ||
                session.inaccessibleCells.contains(cell);
            expect(
              session.board.pieceAt(cell) == null,
              blocked,
              reason: '${level.id} turn $turnIndex cell $cell',
            );
          }
          expect(turnIndex, lessThan(level.moves), reason: level.id);
        }
        if (session.status == LevelStatus.won) {
          expect(session.goals.isComplete, isTrue, reason: level.id);
        } else {
          expect(session.status, LevelStatus.lost, reason: level.id);
          expect(session.movesRemaining, 0, reason: level.id);
        }
      }
    },
    timeout: const Timeout(Duration(minutes: 2)),
  );
}

LevelSession sessionFor(LevelDefinition level, {BoardObjectives? objectives}) {
  Set<Position> cells(String goalId) => {
    for (final goal in level.goals.where((goal) => goal.id == goalId))
      for (final raw in goal.parameters['cells'] as List? ?? [])
        Position(raw[0] as int, raw[1] as int),
  };
  return LevelSession(
    board: BoardGenerator(
      seed: level.seed,
      pieceTypes: level.spawnPool,
    ).generate(rows: level.rows, columns: level.columns),
    turnEngine: TurnEngine(
      resolver: BoardResolver(seed: 20260807),
      shuffler: BoardShuffler(seed: 20260808),
    ),
    moveLimit: level.moves,
    timeLimitSeconds: level.timeLimitSeconds,
    goals: GoalTracker(level.goals.map(GoalState.fromMechanic).toList()),
    blockers: BlockerGrid.fromMechanics(level.blockers),
    boardObjectives:
        objectives ??
        BoardObjectives(
          recipeBaskets: cells('drop_recipe_baskets'),
          cream: cells('spread_cream'),
          ovens: cells('light_ovens'),
        ),
    inaccessibleCells: {
      for (var row = 0; row < level.rows; row++)
        for (var column = 0; column < level.columns; column++)
          if (!level.playableCells.contains(Position(row, column)))
            Position(row, column),
    },
  );
}

List<(Position, Position)> legalMoves(LevelSession session) => [
  for (final first in session.board.positions)
    for (final second in [
      Position(first.row + 1, first.column),
      Position(first.row, first.column + 1),
    ])
      if (!session.blockers.locksSwap(first) &&
          !session.blockers.locksSwap(second) &&
          !session.blockers.blocksCell(first) &&
          !session.blockers.blocksCell(second) &&
          !session.inaccessibleCells.contains(first) &&
          !session.inaccessibleCells.contains(second) &&
          const MoveValidator().isValidSwap(session.board, first, second))
        (first, second),
];
