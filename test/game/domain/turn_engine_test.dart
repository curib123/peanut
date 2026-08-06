import 'package:flutter_test/flutter_test.dart' hide MatchFinder;
import 'package:puff_and_crunch/game/domain/match3.dart';

void main() {
  test('valid turn exposes animation frames and leaves a stable board', () {
    final board = boardFrom(['PEP', 'EPC', 'PES', 'SCE']);
    final engine = TurnEngine(
      resolver: BoardResolver(seed: 8),
      shuffler: BoardShuffler(seed: 9),
    );

    final result = engine.resolveSwap(
      board,
      const Position(0, 1),
      const Position(1, 1),
    );

    expect(result.isValid, isTrue);
    expect(result.cascades, isNotEmpty);
    expect(result.cascades.first.matched, contains(const Position(0, 0)));
    expect(
      result.cascades.first.afterRemoval.pieceAt(const Position(0, 0)),
      isNull,
    );
    expect(const MatchFinder().find(result.finalBoard), isEmpty);
    expect(result.finalBoard.toRows(), board.toRows());
  });

  test('invalid turn does not mutate the board', () {
    final board = boardFrom(['PES', 'CNP', 'OEC']);
    final before = board.toRows();
    final engine = TurnEngine(
      resolver: BoardResolver(seed: 1),
      shuffler: BoardShuffler(seed: 2),
    );

    final result = engine.resolveSwap(
      board,
      const Position(0, 0),
      const Position(0, 1),
    );

    expect(result.isValid, isFalse);
    expect(board.toRows(), before);
  });
}

Board boardFrom(List<String> rows) => Board([
  for (final row in rows) [for (final symbol in row.split('')) piece(symbol)],
]);

Piece piece(String symbol) => Piece(switch (symbol) {
  'P' => PieceKind.peanut,
  'E' => PieceKind.egg,
  'S' => PieceKind.sugarCrystal,
  'C' => PieceKind.caramelRibbon,
  'N' => PieceKind.coconutCream,
  'O' => PieceKind.cocoaCrumb,
  _ => throw ArgumentError.value(symbol),
});
