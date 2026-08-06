import 'board.dart';
import 'board_resolver.dart';
import 'board_shuffler.dart';
import 'match_finder.dart';
import 'move_validator.dart';
import 'position.dart';

class CascadeFrame {
  CascadeFrame({
    required this.matched,
    required this.afterRemoval,
    required this.afterGravity,
    required this.afterRefill,
  });

  final Set<Position> matched;
  final Board afterRemoval;
  final Board afterGravity;
  final Board afterRefill;
}

class TurnResolution {
  TurnResolution.invalid({required Board board})
    : isValid = false,
      afterSwap = board.copy(),
      cascades = const [],
      wasShuffled = false,
      finalBoard = board.copy();

  TurnResolution.valid({
    required this.afterSwap,
    required this.cascades,
    required this.wasShuffled,
    required this.finalBoard,
  }) : isValid = true;

  final bool isValid;
  final Board afterSwap;
  final List<CascadeFrame> cascades;
  final bool wasShuffled;
  final Board finalBoard;
}

class TurnEngine {
  TurnEngine({
    required this.resolver,
    required this.shuffler,
    this.matchFinder = const MatchFinder(),
    this.moveValidator = const MoveValidator(),
  });

  final BoardResolver resolver;
  final BoardShuffler shuffler;
  final MatchFinder matchFinder;
  final MoveValidator moveValidator;

  TurnResolution resolveSwap(
    Board board,
    Position first,
    Position second, {
    int maxCascades = 100,
  }) {
    if (!moveValidator.isValidSwap(board, first, second)) {
      return TurnResolution.invalid(board: board);
    }

    board.swap(first, second);
    final afterSwap = board.copy();
    final cascades = <CascadeFrame>[];
    while (cascades.length < maxCascades) {
      final matches = matchFinder.find(board);
      if (matches.isEmpty) break;
      final matched = {for (final match in matches) ...match.positions};
      resolver.remove(board, matched);
      final afterRemoval = board.copy();
      resolver.applyGravity(board);
      final afterGravity = board.copy();
      resolver.refill(board);
      cascades.add(
        CascadeFrame(
          matched: matched,
          afterRemoval: afterRemoval,
          afterGravity: afterGravity,
          afterRefill: board.copy(),
        ),
      );
    }
    if (matchFinder.find(board).isNotEmpty) {
      throw StateError('Cascade limit of $maxCascades exceeded.');
    }

    var wasShuffled = false;
    if (!moveValidator.hasValidMove(board)) {
      shuffler.shuffle(board);
      wasShuffled = true;
    }
    return TurnResolution.valid(
      afterSwap: afterSwap,
      cascades: List.unmodifiable(cascades),
      wasShuffled: wasShuffled,
      finalBoard: board.copy(),
    );
  }
}
