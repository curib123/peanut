import 'dart:math';

import 'board.dart';
import 'match_finder.dart';
import 'piece.dart';
import 'position.dart';

class CascadeStep {
  CascadeStep({required this.matches, required this.removed});

  final List<MatchGroup> matches;
  final Set<Position> removed;
}

class BoardResolver {
  BoardResolver({
    required int seed,
    this.pieceTypes = PieceKind.regularValues,
    this.matchFinder = const MatchFinder(),
  }) : _random = Random(seed);

  final List<PieceKind> pieceTypes;
  final MatchFinder matchFinder;
  final Random _random;

  void remove(Board board, Iterable<Position> positions) {
    for (final position in positions) {
      board.setPiece(position, null);
    }
  }

  void applyGravity(Board board, {Set<Position> blocked = const {}}) {
    for (var column = 0; column < board.columns; column++) {
      var destination = board.rows - 1;
      for (var row = board.rows - 1; row >= 0; row--) {
        final source = Position(row, column);
        if (blocked.contains(source)) {
          board.setPiece(source, null);
          destination = row - 1;
          continue;
        }
        final piece = board.pieceAt(source);
        if (piece == null) continue;
        board.setPiece(Position(destination, column), piece);
        if (destination != row) board.setPiece(source, null);
        destination--;
      }
      while (destination >= 0) {
        board.setPiece(Position(destination, column), null);
        destination--;
      }
    }
  }

  void refill(Board board, {Set<Position> blocked = const {}}) {
    for (final position in board.positions) {
      if (board.pieceAt(position) == null && !blocked.contains(position)) {
        board.setPiece(
          position,
          Piece(pieceTypes[_random.nextInt(pieceTypes.length)]),
        );
      }
    }
  }

  List<CascadeStep> resolve(
    Board board, {
    int maxCascades = 100,
    Set<Position> blocked = const {},
  }) {
    final steps = <CascadeStep>[];
    while (steps.length < maxCascades) {
      final matches = matchFinder.find(board);
      if (matches.isEmpty) return steps;
      final removed = {for (final match in matches) ...match.positions};
      remove(board, removed);
      applyGravity(board, blocked: blocked);
      refill(board, blocked: blocked);
      steps.add(CascadeStep(matches: matches, removed: removed));
    }
    throw StateError('Cascade limit of $maxCascades exceeded.');
  }
}
