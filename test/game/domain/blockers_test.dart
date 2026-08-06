import 'package:flutter_test/flutter_test.dart';
import 'package:puff_and_crunch/game/domain/match3.dart';

void main() {
  final board = Board.filled(5, 5, const Piece(PieceKind.peanut));
  const center = Position(2, 2);

  test('Sugar Frosting loses layers and clears on the final hit', () {
    final grid = BlockerGrid({
      center: const BlockerState(BlockerKind.sugarFrosting, layers: 2),
    });

    final first = grid.resolveClear(board, {center}, isSpecialClear: false);
    final second = grid.resolveClear(board, {center}, isSpecialClear: false);

    expect(first.removed, isEmpty);
    expect(grid.at(center), isNull);
    expect(second.removed[BlockerKind.sugarFrosting], 1);
  });

  test('Peanut Crate occupies a cell and breaks from an adjacent match', () {
    final grid = BlockerGrid({
      center: const BlockerState(BlockerKind.peanutCrate),
    });

    expect(grid.blocksCell(center), isTrue);
    expect(
      grid.resolveClear(board, {
        const Position(2, 1),
      }, isSpecialClear: false).removed,
      containsPair(BlockerKind.peanutCrate, 1),
    );
  });

  test('Sticky Caramel locks its piece until directly cleared', () {
    final grid = BlockerGrid({
      center: const BlockerState(BlockerKind.stickyCaramel),
    });

    expect(grid.locksSwap(center), isTrue);
    grid.resolveClear(board, {center}, isSpecialClear: false);
    expect(grid.locksSwap(center), isFalse);
  });

  test('Chocolate Crumbs spread only on a turn when none were damaged', () {
    final grid = BlockerGrid({
      center: const BlockerState(BlockerKind.chocolateCrumbs, layers: 2),
    });

    expect(grid.endTurnChocolateSpread(board), isNotNull);
    grid.resolveClear(board, {center}, isSpecialClear: false);
    expect(grid.endTurnChocolateSpread(board), isNull);
  });

  test('Oven Stone needs an adjacent normal hit or a direct special hit', () {
    final normal = BlockerGrid({
      center: const BlockerState(BlockerKind.ovenStone),
    });
    normal.resolveClear(board, {center}, isSpecialClear: false);
    expect(normal.at(center), isNotNull);
    normal.resolveClear(board, {const Position(2, 1)}, isSpecialClear: false);
    expect(normal.at(center), isNull);

    final special = BlockerGrid({
      center: const BlockerState(BlockerKind.ovenStone),
    });
    special.resolveClear(board, {center}, isSpecialClear: true);
    expect(special.at(center), isNull);
  });

  test("Baker's Twine prevents swaps and is cut by a match", () {
    final grid = BlockerGrid({
      center: const BlockerState(BlockerKind.bakersTwine),
    });

    expect(grid.locksSwap(center), isTrue);
    expect(
      grid.resolveClear(board, {center}, isSpecialClear: false).removed,
      containsPair(BlockerKind.bakersTwine, 1),
    );
  });

  test(
    'every blocker responds to a special clear without duplicate removal',
    () {
      for (final kind in BlockerKind.values) {
        final grid = BlockerGrid({center: BlockerState(kind)});
        final first = grid.resolveClear(board, {center}, isSpecialClear: true);
        final second = grid.resolveClear(board, {center}, isSpecialClear: true);
        expect(first.removed[kind], 1, reason: kind.name);
        expect(second.removed[kind], isNull, reason: kind.name);
      }
    },
  );

  test('blocker definitions load from stable content IDs', () {
    final grid = BlockerGrid.fromMechanics([
      MechanicDefinition(
        id: 'sugar_frosting',
        parameters: {'row': 1, 'column': 2, 'layers': 2},
      ),
    ]);

    expect(grid.at(const Position(1, 2))?.layers, 2);
  });

  test('gravity and refill preserve hard-blocked cells', () {
    final testBoard = Board([
      [const Piece(PieceKind.egg)],
      [null],
      [const Piece(PieceKind.peanut)],
      [null],
      [const Piece(PieceKind.sugarCrystal)],
    ]);
    final blocked = {const Position(2, 0)};
    final resolver = BoardResolver(seed: 10);

    resolver.applyGravity(testBoard, blocked: blocked);
    resolver.refill(testBoard, blocked: blocked);

    expect(testBoard.pieceAt(const Position(2, 0)), isNull);
    expect(
      testBoard.positions
          .where((position) => !blocked.contains(position))
          .every((position) => testBoard.pieceAt(position) != null),
      isTrue,
    );
  });
}
