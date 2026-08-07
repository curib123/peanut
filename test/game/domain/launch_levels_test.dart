import 'package:flutter_test/flutter_test.dart' hide MatchFinder;
import 'package:puff_and_crunch/game/domain/match3.dart';
import 'package:puff_and_crunch/services/content/bundled_level_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('all 120 launch levels load in six ordered worlds', () async {
    final levels = await const BundledLevelRepository().loadLaunchLevels();
    expect(levels, hasLength(120));
    expect(
      levels.map((level) => level.order),
      orderedEquals(List.generate(120, (index) => index + 1)),
    );
    expect(levels.map((level) => level.worldId).toSet(), {
      'sunrise_bakery',
      'peanut_grove',
      'egg_cloud_kitchen',
      'sugar_harbor',
      'festival_oven',
      'starlight_bake_off',
    });
    expect(levels.every((level) => level.tutorial.isNotEmpty), isTrue);
    expect(levels.every((level) => level.goals.isNotEmpty), isTrue);
  });

  test('all levels have valid mechanics and playable openings', () async {
    final levels = await const BundledLevelRepository().loadLaunchLevels();
    for (final level in levels) {
      final blockers = BlockerGrid.fromMechanics(level.blockers);
      final board = BoardGenerator(
        seed: level.seed,
        pieceTypes: level.spawnPool,
      ).generate();
      final blocked = {...blockers.blockingPositions};
      for (final cell in board.positions.where(
        (cell) => !level.playableCells.contains(cell),
      )) {
        blocked.add(cell);
      }
      for (final cell in blocked) {
        board.setPiece(cell, null);
      }
      expect(const MatchFinder().find(board), isEmpty, reason: level.id);
      expect(_hasMove(board, blocked), isTrue, reason: level.id);
      for (final goal in level.goals) {
        expect(
          () => GoalState.fromMechanic(goal),
          returnsNormally,
          reason: level.id,
        );
      }
    }
  });

  test('every world has ten move levels and ten time trials', () async {
    final levels = await const BundledLevelRepository().loadLaunchLevels();
    for (final worldId in levels.map((level) => level.worldId).toSet()) {
      final world = levels.where((level) => level.worldId == worldId).toList();
      expect(world, hasLength(20), reason: worldId);
      expect(
        world.where((level) => level.timeLimitSeconds == null),
        hasLength(10),
      );
      expect(
        world.where((level) => level.timeLimitSeconds != null),
        hasLength(10),
      );
    }
  });
}

bool _hasMove(Board board, Set<Position> blocked) {
  const validator = MoveValidator();
  for (final first in board.positions) {
    if (blocked.contains(first)) continue;
    for (final second in [
      Position(first.row, first.column + 1),
      Position(first.row + 1, first.column),
    ]) {
      if (board.contains(second) &&
          !blocked.contains(second) &&
          validator.isValidSwap(board, first, second)) {
        return true;
      }
    }
  }
  return false;
}
