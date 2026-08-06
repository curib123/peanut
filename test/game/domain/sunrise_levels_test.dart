import 'package:flutter_test/flutter_test.dart' hide MatchFinder;
import 'package:puff_and_crunch/game/domain/match3.dart';
import 'package:puff_and_crunch/services/content/bundled_level_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'all ten Sunrise Bakery JSON levels load in increasing difficulty',
    () async {
      final levels = await const BundledLevelRepository().loadSunriseBakery();

      expect(levels, hasLength(10));
      expect(
        levels.map((level) => level.order),
        orderedEquals(List.generate(10, (i) => i + 1)),
      );
      expect(levels.every((level) => level.tutorial.isNotEmpty), isTrue);
      expect(
        levels.map((level) => level.metadata['difficulty']),
        orderedEquals(List.generate(10, (i) => i + 1)),
      );
      expect(levels[5].playableCells.length, lessThan(64));
      expect(
        levels[7].blockers.every(
          (blocker) => blocker.parameters['layers'] == 2,
        ),
        isTrue,
      );
      expect(levels.last.goals, hasLength(3));
    },
  );

  test('every level creates deterministic playable opening boards', () async {
    final levels = await const BundledLevelRepository().loadSunriseBakery();
    for (final level in levels) {
      final first = BoardGenerator(
        seed: level.seed,
        pieceTypes: level.spawnPool,
      ).generate(rows: level.rows, columns: level.columns);
      final second = BoardGenerator(
        seed: level.seed,
        pieceTypes: level.spawnPool,
      ).generate(rows: level.rows, columns: level.columns);
      for (final cell in first.positions.where(
        (cell) => !level.playableCells.contains(cell),
      )) {
        first.setPiece(cell, null);
        second.setPiece(cell, null);
      }
      expect(first.toRows(), second.toRows(), reason: level.id);
      expect(const MatchFinder().find(first), isEmpty, reason: level.id);
      expect(
        const MoveValidator().hasValidMove(first),
        isTrue,
        reason: level.id,
      );
      expect(level.moves, greaterThanOrEqualTo(18), reason: level.id);
      for (final goal in level.goals) {
        expect(
          () => GoalState.fromMechanic(goal),
          returnsNormally,
          reason: level.id,
        );
      }
      expect(
        () => BlockerGrid.fromMechanics(level.blockers),
        returnsNormally,
        reason: level.id,
      );
    }
  });

  test(
    'irregular cells stay inaccessible throughout a level session',
    () async {
      final level = await const BundledLevelRepository().load(6);
      final board = BoardGenerator(
        seed: level.seed,
        pieceTypes: level.spawnPool,
      ).generate();
      final inaccessible = board.positions
          .where((cell) => !level.playableCells.contains(cell))
          .toSet();
      final session = LevelSession(
        turnEngine: TurnEngine(
          resolver: BoardResolver(seed: 1),
          shuffler: BoardShuffler(seed: 2),
        ),
        board: board,
        moveLimit: level.moves,
        goals: GoalTracker(level.goals.map(GoalState.fromMechanic).toList()),
        inaccessibleCells: inaccessible,
      );
      final hole = inaccessible.first;
      expect(board.pieceAt(hole), isNull);
      final neighbor = board.positions.firstWhere(
        hole.isOrthogonallyAdjacentTo,
      );
      expect(session.play(hole, neighbor).resolution.isValid, isFalse);
      expect(board.pieceAt(hole), isNull);
    },
  );
}
