import 'package:flutter_test/flutter_test.dart';
import 'package:puff_and_crunch/game/domain/match3.dart';

void main() {
  const resolver = SpecialResolver();

  group('special creation', () {
    test('four-piece line creates an oriented Sugar Beam', () {
      final board = plainBoard();
      final plan = resolver.resolveMatches(board, [
        matchGroup(
          PieceKind.peanut,
          MatchOrientation.horizontal,
          row: 2,
          length: 4,
        ),
      ], preferredPosition: const Position(2, 2));

      final created = plan.created[const Position(2, 2)]!;
      expect(created.specialKind, SpecialKind.sugarBeam);
      expect(created.beamOrientation, BeamOrientation.horizontal);
    });

    test('five-piece line creates a Golden Recipe Spark', () {
      final plan = resolver.resolveMatches(plainBoard(), [
        matchGroup(
          PieceKind.egg,
          MatchOrientation.vertical,
          column: 3,
          length: 5,
        ),
      ]);

      expect(
        plan.created.values.single.specialKind,
        SpecialKind.goldenRecipeSpark,
      );
    });

    test('T or L intersection creates an Oven Burst', () {
      final positions = {
        const Position(1, 2),
        const Position(2, 2),
        const Position(3, 2),
        const Position(1, 1),
        const Position(1, 3),
      };
      final plan = resolver.resolveMatches(plainBoard(), [
        MatchGroup(type: PieceKind.sugarCrystal, positions: positions),
      ]);

      expect(plan.created.values.single.specialKind, SpecialKind.ovenBurst);
    });

    test('2x2 square creates a Peanut Spinner', () {
      final positions = {
        const Position(1, 1),
        const Position(1, 2),
        const Position(2, 1),
        const Position(2, 2),
      };
      final plan = resolver.resolveMatches(plainBoard(), [
        MatchGroup(type: PieceKind.caramelRibbon, positions: positions),
      ]);

      expect(plan.created.values.single.specialKind, SpecialKind.peanutSpinner);
    });
  });

  group('individual activation', () {
    test('Sugar Beam clears its entire oriented line', () {
      final board = plainBoard()
        ..setPiece(const Position(3, 3), beam(BeamOrientation.horizontal));
      final plan = resolver.activationForSwap(
        board,
        const Position(3, 3),
        const Position(3, 4),
      )!;

      expect(plan.cleared.where((position) => position.row == 3), hasLength(7));
    });

    test('Golden Recipe Spark clears all pieces of the swapped type', () {
      final board = plainBoard()
        ..setPiece(const Position(3, 3), spark())
        ..setPiece(const Position(3, 4), const Piece(PieceKind.egg))
        ..setPiece(const Position(0, 0), const Piece(PieceKind.egg))
        ..setPiece(const Position(6, 6), const Piece(PieceKind.egg));
      final plan = resolver.activationForSwap(
        board,
        const Position(3, 3),
        const Position(3, 4),
      )!;

      expect(
        plan.cleared,
        containsAll([const Position(0, 0), const Position(6, 6)]),
      );
    });

    test('Oven Burst clears a nearby area', () {
      final board = plainBoard()..setPiece(const Position(3, 3), burst());
      final plan = resolver.activationForSwap(
        board,
        const Position(3, 3),
        const Position(3, 4),
      )!;

      expect(
        plan.cleared,
        containsAll([const Position(2, 2), const Position(4, 4)]),
      );
    });

    test('Peanut Spinner targets and clears near an important special', () {
      final board = plainBoard()
        ..setPiece(const Position(0, 0), spinner())
        ..setPiece(const Position(5, 5), burst());
      final plan = resolver.activationForSwap(
        board,
        const Position(0, 0),
        const Position(0, 1),
      )!;

      expect(plan.cleared, contains(const Position(5, 5)));
      expect(plan.activated, contains(const Position(5, 5)));
    });
  });

  group('special combinations', () {
    test('identical adjacent specials remain a valid swap', () {
      final board = comboBoard(
        beam(BeamOrientation.horizontal),
        beam(BeamOrientation.horizontal),
      );

      expect(
        const MoveValidator().isValidSwap(
          board,
          const Position(2, 2),
          const Position(2, 3),
        ),
        isTrue,
      );
    });

    test('Beam plus Beam clears both rows and columns once', () {
      final board = comboBoard(
        beam(BeamOrientation.horizontal),
        beam(BeamOrientation.vertical),
      );
      final plan = activatePair(resolver, board);
      expect(
        plan.cleared,
        containsAll([const Position(0, 2), const Position(6, 3)]),
      );
      expect(plan.activated, hasLength(2));
    });

    test('Beam plus Oven Burst clears three rows and columns', () {
      final plan = activatePair(
        resolver,
        comboBoard(beam(BeamOrientation.horizontal), burst()),
      );
      expect(plan.cleared.length, greaterThanOrEqualTo(30));
    });

    test('Oven Burst plus Oven Burst clears a large combined area', () {
      final plan = activatePair(resolver, comboBoard(burst(), burst()));
      expect(plan.cleared.length, greaterThanOrEqualTo(25));
    });

    test('Recipe Spark plus regular clears every piece of that type', () {
      final board = comboBoard(spark(), const Piece(PieceKind.egg))
        ..setPiece(const Position(0, 0), const Piece(PieceKind.egg));
      expect(
        activatePair(resolver, board).cleared,
        contains(const Position(0, 0)),
      );
    });

    test('Recipe Spark plus Beam clears target pieces and their lines', () {
      final board = comboBoard(spark(), beam(BeamOrientation.horizontal))
        ..setPiece(const Position(0, 0), const Piece(PieceKind.peanut));
      final plan = activatePair(resolver, board);
      expect(plan.cleared.where((position) => position.row == 0), hasLength(7));
    });

    test('Recipe Spark plus Oven Burst clears areas around target pieces', () {
      final board = comboBoard(spark(), burst())
        ..setPiece(const Position(0, 0), const Piece(PieceKind.peanut));
      final plan = activatePair(resolver, board);
      expect(
        plan.cleared,
        containsAll([const Position(0, 0), const Position(1, 1)]),
      );
    });

    test('Recipe Spark plus Recipe Spark clears the board', () {
      final plan = activatePair(resolver, comboBoard(spark(), spark()));
      expect(plan.cleared, hasLength(49));
    });

    test('Spinner plus special activates the partner without duplicates', () {
      final plan = activatePair(
        resolver,
        comboBoard(spinner(), beam(BeamOrientation.vertical)),
      );
      expect(
        plan.activated,
        containsAll([const Position(2, 2), const Position(2, 3)]),
      );
      expect(plan.activated, hasLength(2));
    });
  });
}

SpecialPlan activatePair(SpecialResolver resolver, Board board) => resolver
    .activationForSwap(board, const Position(2, 2), const Position(2, 3))!;

Board comboBoard(Piece first, Piece second) => plainBoard()
  ..setPiece(const Position(2, 2), first)
  ..setPiece(const Position(2, 3), second);

Board plainBoard() => Board([
  for (var row = 0; row < 7; row++)
    [
      for (var column = 0; column < 7; column++)
        Piece(
          PieceKind.regularValues[(row * 2 + column) %
              PieceKind.regularValues.length],
        ),
    ],
]);

MatchGroup matchGroup(
  PieceKind kind,
  MatchOrientation orientation, {
  int row = 0,
  int column = 0,
  required int length,
}) => MatchGroup(
  type: kind,
  positions: {
    for (var index = 0; index < length; index++)
      Position(
        orientation == MatchOrientation.vertical ? index : row,
        orientation == MatchOrientation.horizontal ? index : column,
      ),
  },
);

Piece beam(BeamOrientation orientation) => Piece(
  PieceKind.peanut,
  specialKind: SpecialKind.sugarBeam,
  beamOrientation: orientation,
);

Piece spark() =>
    const Piece(PieceKind.peanut, specialKind: SpecialKind.goldenRecipeSpark);

Piece burst() =>
    const Piece(PieceKind.peanut, specialKind: SpecialKind.ovenBurst);

Piece spinner() =>
    const Piece(PieceKind.peanut, specialKind: SpecialKind.peanutSpinner);
