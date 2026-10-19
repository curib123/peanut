import 'board.dart';
import 'match_finder.dart';
import 'position.dart';

class MoveValidator {
  const MoveValidator({this.matchFinder = const MatchFinder()});

  final MatchFinder matchFinder;

  bool isValidSwap(
    Board board,
    Position first,
    Position second, {
    Set<Position> unavailableCells = const {},
  }) {
    if (unavailableCells.contains(first) ||
        unavailableCells.contains(second) ||
        !board.contains(first) ||
        !board.contains(second) ||
        !first.isOrthogonallyAdjacentTo(second) ||
        board.pieceAt(first) == null ||
        board.pieceAt(second) == null) {
      return false;
    }

    if (board.pieceAt(first)!.isSpecial || board.pieceAt(second)!.isSpecial) {
      return true;
    }
    if (board.pieceAt(first) == board.pieceAt(second)) return false;
    board.swap(first, second);
    final createsMatch = matchFinder
        .find(board)
        .any(
          (group) =>
              group.positions.contains(first) ||
              group.positions.contains(second),
        );
    board.swap(first, second);
    return createsMatch;
  }

  bool hasValidMove(Board board, {Set<Position> unavailableCells = const {}}) {
    for (final position in board.positions) {
      final right = Position(position.row, position.column + 1);
      final below = Position(position.row + 1, position.column);
      if (board.contains(right) &&
          isValidSwap(
            board,
            position,
            right,
            unavailableCells: unavailableCells,
          )) {
        return true;
      }
      if (board.contains(below) &&
          isValidSwap(
            board,
            position,
            below,
            unavailableCells: unavailableCells,
          )) {
        return true;
      }
    }
    return false;
  }
}
