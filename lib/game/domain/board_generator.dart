import 'dart:math';

import 'board.dart';
import 'match_finder.dart';
import 'move_validator.dart';
import 'piece.dart';

class BoardGenerator {
  BoardGenerator({
    required int seed,
    this.pieceTypes = PieceKind.regularValues,
    this.matchFinder = const MatchFinder(),
    this.moveValidator = const MoveValidator(),
  }) : assert(pieceTypes.length >= 3),
       _random = Random(seed);

  final List<PieceKind> pieceTypes;
  final MatchFinder matchFinder;
  final MoveValidator moveValidator;
  final Random _random;

  Board generate({int rows = 8, int columns = 8, int maxAttempts = 200}) {
    for (var attempt = 0; attempt < maxAttempts; attempt++) {
      final cells = <List<Piece?>>[];
      for (var row = 0; row < rows; row++) {
        final current = <Piece?>[];
        cells.add(current);
        for (var column = 0; column < columns; column++) {
          final blocked = <PieceKind>{};
          if (column >= 2 && current[column - 1] == current[column - 2]) {
            blocked.add(current[column - 1]!.kind);
          }
          if (row >= 2 && cells[row - 1][column] == cells[row - 2][column]) {
            blocked.add(cells[row - 1][column]!.kind);
          }
          final choices = pieceTypes
              .where((type) => !blocked.contains(type))
              .toList();
          current.add(Piece(choices[_random.nextInt(choices.length)]));
        }
      }
      final board = Board(cells);
      if (matchFinder.find(board).isEmpty &&
          moveValidator.hasValidMove(board)) {
        return board;
      }
    }
    throw StateError(
      'Could not generate a playable board in $maxAttempts attempts.',
    );
  }
}
