import 'board.dart';
import 'board_resolver.dart';
import 'board_shuffler.dart';
import 'match_finder.dart';
import 'move_validator.dart';
import 'position.dart';
import 'special_resolver.dart';

class CascadeFrame {
  CascadeFrame({
    required this.matched,
    required this.beforeClear,
    required this.afterRemoval,
    required this.afterGravity,
    required this.afterRefill,
    required this.activatedSpecials,
  });

  final Set<Position> matched;
  final Board beforeClear;
  final Board afterRemoval;
  final Board afterGravity;
  final Board afterRefill;
  final Set<Position> activatedSpecials;
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
    this.specialResolver = const SpecialResolver(),
  });

  final BoardResolver resolver;
  final BoardShuffler shuffler;
  final MatchFinder matchFinder;
  final MoveValidator moveValidator;
  final SpecialResolver specialResolver;

  bool ensurePlayable(
    Board board, {
    Set<Position> unavailableCells = const {},
  }) {
    if (moveValidator.hasValidMove(board, unavailableCells: unavailableCells)) {
      return false;
    }
    shuffler.shuffle(board, unavailableCells: unavailableCells);
    return true;
  }

  TurnResolution resolveSwap(
    Board board,
    Position first,
    Position second, {
    int maxCascades = 100,
    Set<Position> blockedCells = const {},
    Set<Position> lockedCells = const {},
    // Called synchronously before gravity so removed blockers open immediately.
    // The owner may update blockedCells/lockedCells for subsequent cascades.
    void Function(Board beforeClear, SpecialPlan plan)? onClear,
  }) {
    if (!moveValidator.isValidSwap(
      board,
      first,
      second,
      unavailableCells: {...blockedCells, ...lockedCells},
    )) {
      return TurnResolution.invalid(board: board);
    }

    board.swap(first, second);
    final afterSwap = board.copy();
    final cascades = <CascadeFrame>[];
    var pendingSpecial = specialResolver.activationForSwap(
      board,
      first,
      second,
    );
    while (cascades.length < maxCascades) {
      final SpecialPlan plan;
      if (pendingSpecial != null) {
        plan = pendingSpecial;
        pendingSpecial = null;
      } else {
        final matches = matchFinder.find(board);
        if (matches.isEmpty) break;
        plan = specialResolver.resolveMatches(
          board,
          matches,
          preferredPosition: cascades.isEmpty ? second : null,
        );
      }
      final beforeClear = board.copy();
      resolver.remove(board, plan.cleared);
      for (final creation in plan.created.entries) {
        board.setPiece(creation.key, creation.value);
      }
      final afterRemoval = board.copy();
      onClear?.call(beforeClear, plan);
      resolver.applyGravity(board, blocked: blockedCells);
      final afterGravity = board.copy();
      resolver.refill(board, blocked: blockedCells);
      cascades.add(
        CascadeFrame(
          matched: plan.cleared,
          beforeClear: beforeClear,
          afterRemoval: afterRemoval,
          afterGravity: afterGravity,
          afterRefill: board.copy(),
          activatedSpecials: plan.activated,
        ),
      );
    }
    if (matchFinder.find(board).isNotEmpty) {
      throw StateError('Cascade limit of $maxCascades exceeded.');
    }

    final wasShuffled = ensurePlayable(
      board,
      unavailableCells: {...blockedCells, ...lockedCells},
    );
    return TurnResolution.valid(
      afterSwap: afterSwap,
      cascades: List.unmodifiable(cascades),
      wasShuffled: wasShuffled,
      finalBoard: board.copy(),
    );
  }
}
