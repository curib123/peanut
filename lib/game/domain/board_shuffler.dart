import 'dart:math';

import 'board.dart';
import 'match_finder.dart';
import 'move_validator.dart';
import 'piece.dart';
import 'position.dart';

class BoardShuffler {
  BoardShuffler({
    required int seed,
    this.matchFinder = const MatchFinder(),
    this.moveValidator = const MoveValidator(),
  }) : _random = Random(seed);

  final MatchFinder matchFinder;
  final MoveValidator moveValidator;
  final Random _random;

  void shuffle(
    Board board, {
    int maxAttempts = 1000,
    Set<Position> unavailableCells = const {},
  }) {
    final occupied = board.positions
        .where(
          (position) =>
              !unavailableCells.contains(position) &&
              board.pieceAt(position) != null,
        )
        .toList();
    final pieces = occupied.map(board.pieceAt).whereType<Piece>().toList();

    for (var attempt = 0; attempt < maxAttempts; attempt++) {
      pieces.shuffle(_random);
      var index = 0;
      for (final position in occupied) {
        board.setPiece(position, pieces[index++]);
      }
      if (matchFinder.find(board).isEmpty &&
          moveValidator.hasValidMove(
            board,
            unavailableCells: unavailableCells,
          )) {
        return;
      }
    }
    throw StateError('Could not shuffle into a playable board.');
  }
}
