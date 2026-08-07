import 'board.dart';
import 'match_finder.dart';
import 'piece.dart';
import 'position.dart';

class SpecialPlan {
  SpecialPlan({
    required Set<Position> cleared,
    Map<Position, Piece> created = const {},
    Set<Position> activated = const {},
  }) : cleared = Set.unmodifiable(cleared),
       created = Map.unmodifiable(created),
       activated = Set.unmodifiable(activated);

  final Set<Position> cleared;
  final Map<Position, Piece> created;
  final Set<Position> activated;
}

class SpecialResolver {
  const SpecialResolver();

  SpecialPlan? activationForSwap(Board board, Position first, Position second) {
    final firstPiece = board.pieceAt(first);
    final secondPiece = board.pieceAt(second);
    if (firstPiece == null || secondPiece == null) return null;
    if (!firstPiece.isSpecial && !secondPiece.isSpecial) return null;

    final firstSpecial = firstPiece.specialKind;
    final secondSpecial = secondPiece.specialKind;
    final seeds = <Position>{first, second};

    if (firstSpecial == SpecialKind.goldenRecipeSpark &&
        secondSpecial == SpecialKind.goldenRecipeSpark) {
      return SpecialPlan(cleared: board.positions.toSet(), activated: seeds);
    }
    if (firstSpecial == SpecialKind.goldenRecipeSpark ||
        secondSpecial == SpecialKind.goldenRecipeSpark) {
      final sparkPosition = firstSpecial == SpecialKind.goldenRecipeSpark
          ? first
          : second;
      final partnerPosition = sparkPosition == first ? second : first;
      final partner = board.pieceAt(partnerPosition)!;
      return _sparkCombination(board, sparkPosition, partnerPosition, partner);
    }
    if (firstSpecial == SpecialKind.sugarBeam &&
        secondSpecial == SpecialKind.sugarBeam) {
      return SpecialPlan(
        cleared: {
          ..._row(board, first.row),
          ..._column(board, first.column),
          ..._row(board, second.row),
          ..._column(board, second.column),
        },
        activated: seeds,
      );
    }
    if (_isPair(
      firstSpecial,
      secondSpecial,
      SpecialKind.sugarBeam,
      SpecialKind.ovenBurst,
    )) {
      final center = firstSpecial == SpecialKind.ovenBurst ? first : second;
      return SpecialPlan(
        cleared: _crossBands(board, center, radius: 1),
        activated: seeds,
      );
    }
    if (firstSpecial == SpecialKind.ovenBurst &&
        secondSpecial == SpecialKind.ovenBurst) {
      return SpecialPlan(
        cleared: {..._area(board, first, 2), ..._area(board, second, 2)},
        activated: seeds,
      );
    }
    if (firstSpecial == SpecialKind.peanutSpinner ||
        secondSpecial == SpecialKind.peanutSpinner) {
      final specialPosition = firstSpecial == SpecialKind.peanutSpinner
          ? second
          : first;
      return _expand(board, {..._area(board, specialPosition, 1), ...seeds});
    }
    return _expand(board, seeds);
  }

  SpecialPlan resolveMatches(
    Board board,
    List<MatchGroup> matches, {
    Position? preferredPosition,
  }) {
    final cleared = <Position>{};
    final created = <Position, Piece>{};
    for (final match in matches) {
      final creation = _creationFor(board, match, preferredPosition);
      cleared.addAll(match.positions);
      if (creation != null) {
        cleared.remove(creation.$1);
        created[creation.$1] = creation.$2;
      }
    }
    final recipeTypes = matches.map((match) => match.type).toSet();
    if (recipeTypes.containsAll({
      PieceKind.peanut,
      PieceKind.egg,
      PieceKind.sugarCrystal,
    })) {
      final recipePositions = <Position>{
        for (final match in matches)
          if (match.type == PieceKind.peanut ||
              match.type == PieceKind.egg ||
              match.type == PieceKind.sugarCrystal)
            ...match.positions,
      };
      final available =
          recipePositions.difference(created.keys.toSet()).toList()..sort(
            (a, b) => a.row != b.row
                ? a.row.compareTo(b.row)
                : a.column.compareTo(b.column),
          );
      if (available.isNotEmpty) {
        final position =
            preferredPosition != null && available.contains(preferredPosition)
            ? preferredPosition
            : available.first;
        cleared.remove(position);
        created[position] = const Piece(
          PieceKind.peanut,
          specialKind: SpecialKind.peanutKisses,
        );
      }
    }
    final expanded = _expand(board, cleared);
    return SpecialPlan(
      cleared: expanded.cleared.difference(created.keys.toSet()),
      created: created,
      activated: expanded.activated,
    );
  }

  (Position, Piece)? _creationFor(
    Board board,
    MatchGroup match,
    Position? preferredPosition,
  ) {
    final ordered = match.positions.toList()
      ..sort(
        (a, b) => a.row != b.row
            ? a.row.compareTo(b.row)
            : a.column.compareTo(b.column),
      );
    final candidates = ordered
        .where((position) => board.pieceAt(position)?.isSpecial != true)
        .toList();
    if (candidates.isEmpty) return null;
    final position =
        preferredPosition != null && candidates.contains(preferredPosition)
        ? preferredPosition
        : candidates.first;
    if (match.orientation == MatchOrientation.square) {
      return (
        position,
        Piece(match.type, specialKind: SpecialKind.peanutSpinner),
      );
    }
    if (match.orientation == MatchOrientation.intersecting) {
      return (position, Piece(match.type, specialKind: SpecialKind.ovenBurst));
    }
    if (match.positions.length >= 5) {
      return (
        position,
        Piece(match.type, specialKind: SpecialKind.goldenRecipeSpark),
      );
    }
    if (match.positions.length == 4) {
      return (
        position,
        Piece(
          match.type,
          specialKind: SpecialKind.sugarBeam,
          beamOrientation: match.orientation == MatchOrientation.horizontal
              ? BeamOrientation.horizontal
              : BeamOrientation.vertical,
        ),
      );
    }
    return null;
  }

  SpecialPlan _sparkCombination(
    Board board,
    Position spark,
    Position partnerPosition,
    Piece partner,
  ) {
    final targets = board.positions
        .where((position) => board.pieceAt(position)?.kind == partner.kind)
        .toSet();
    final cleared = <Position>{spark, partnerPosition, ...targets};
    if (partner.specialKind == SpecialKind.sugarBeam) {
      for (final target in targets) {
        cleared.addAll(
          partner.beamOrientation == BeamOrientation.horizontal
              ? _row(board, target.row)
              : _column(board, target.column),
        );
      }
    } else if (partner.specialKind == SpecialKind.ovenBurst) {
      for (final target in targets) {
        cleared.addAll(_area(board, target, 1));
      }
    }
    return _expand(board, cleared);
  }

  SpecialPlan _expand(Board board, Set<Position> initial) {
    final cleared = <Position>{...initial};
    final activated = <Position>{};
    final queue = <Position>[...initial];
    while (queue.isNotEmpty) {
      final position = queue.removeLast();
      final piece = board.contains(position) ? board.pieceAt(position) : null;
      if (piece == null || !piece.isSpecial || !activated.add(position)) {
        continue;
      }
      final effect = switch (piece.specialKind!) {
        SpecialKind.sugarBeam =>
          piece.beamOrientation == BeamOrientation.horizontal
              ? _row(board, position.row)
              : _column(board, position.column),
        SpecialKind.goldenRecipeSpark =>
          board.positions
              .where((target) => board.pieceAt(target)?.kind == piece.kind)
              .toSet(),
        SpecialKind.ovenBurst => _area(board, position, 1),
        SpecialKind.peanutSpinner => _area(
          board,
          _spinnerTarget(board, position),
          1,
        ),
        SpecialKind.peanutKisses =>
          board.positions
              .where(
                (target) =>
                    _isPeanutKissesIngredient(board.pieceAt(target)?.kind),
              )
              .toSet(),
      };
      for (final target in effect) {
        if (cleared.add(target)) queue.add(target);
      }
    }
    return SpecialPlan(cleared: cleared, activated: activated);
  }

  Position _spinnerTarget(Board board, Position origin) {
    for (final position in board.positions) {
      if (position != origin && board.pieceAt(position)?.isSpecial == true) {
        return position;
      }
    }
    return Position(board.rows ~/ 2, board.columns ~/ 2);
  }

  Set<Position> _row(Board board, int row) => {
    for (var column = 0; column < board.columns; column++)
      Position(row, column),
  };

  Set<Position> _column(Board board, int column) => {
    for (var row = 0; row < board.rows; row++) Position(row, column),
  };

  Set<Position> _area(Board board, Position center, int radius) => {
    for (var row = center.row - radius; row <= center.row + radius; row++)
      for (
        var column = center.column - radius;
        column <= center.column + radius;
        column++
      )
        if (board.contains(Position(row, column))) Position(row, column),
  };

  Set<Position> _crossBands(
    Board board,
    Position center, {
    required int radius,
  }) => {
    for (var offset = -radius; offset <= radius; offset++)
      if (center.row + offset >= 0 && center.row + offset < board.rows)
        ..._row(board, center.row + offset),
    for (var offset = -radius; offset <= radius; offset++)
      if (center.column + offset >= 0 && center.column + offset < board.columns)
        ..._column(board, center.column + offset),
  };

  bool _isPair(
    SpecialKind? first,
    SpecialKind? second,
    SpecialKind a,
    SpecialKind b,
  ) => (first == a && second == b) || (first == b && second == a);

  bool _isPeanutKissesIngredient(PieceKind? kind) =>
      kind == PieceKind.peanut ||
      kind == PieceKind.egg ||
      kind == PieceKind.sugarCrystal;
}
