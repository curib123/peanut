import 'package:flutter_test/flutter_test.dart' hide MatchFinder;
import 'package:puff_and_crunch/game/domain/match3.dart';

void main() {
  group('match detection', () {
    test('finds a horizontal match', () {
      final matches = const MatchFinder().find(
        boardFrom(['PPP', 'ESC', 'CEC']),
      );

      expect(matches, hasLength(1));
      expect(matches.single.orientation, MatchOrientation.horizontal);
      expect(matches.single.positions, hasLength(3));
    });

    test('finds a vertical match', () {
      final matches = const MatchFinder().find(
        boardFrom(['PEC', 'PCE', 'PES']),
      );

      expect(matches, hasLength(1));
      expect(matches.single.orientation, MatchOrientation.vertical);
    });

    test('keeps separate matches in multiple locations', () {
      final matches = const MatchFinder().find(
        boardFrom(['PPPES', 'ESCSP', 'CCCEE']),
      );

      expect(matches, hasLength(2));
    });

    test('merges intersecting runs into one group', () {
      final matches = const MatchFinder().find(
        boardFrom(['ECPCE', 'SPPPS', 'ECPCE']),
      );

      expect(matches, hasLength(1));
      expect(matches.single.orientation, MatchOrientation.intersecting);
      expect(matches.single.positions, hasLength(5));
    });
  });

  group('move validation', () {
    const validator = MoveValidator();

    test('accepts a swap that creates a match', () {
      final board = boardFrom(['PEP', 'EPC', 'PES']);

      expect(
        validator.isValidSwap(
          board,
          const Position(0, 1),
          const Position(1, 1),
        ),
        isTrue,
      );
    });

    test('rejects invalid and non-adjacent swaps without changing board', () {
      final board = boardFrom(['PEC', 'CSP', 'ECP']);
      final original = board.toRows();

      expect(
        validator.isValidSwap(
          board,
          const Position(0, 0),
          const Position(0, 1),
        ),
        isFalse,
      );
      expect(
        validator.isValidSwap(
          board,
          const Position(0, 0),
          const Position(2, 0),
        ),
        isFalse,
      );
      expect(board.toRows(), original);
    });

    test('detects a board with no valid move', () {
      final board = boardFrom(['PE', 'SC']);

      expect(validator.hasValidMove(board), isFalse);
    });
  });

  group('board resolution', () {
    test('gravity compacts pieces toward the bottom', () {
      final board = boardFromNullable([
        [piece('P'), null],
        [null, piece('E')],
        [piece('S'), piece('C')],
      ]);

      BoardResolver(seed: 1).applyGravity(board);

      expect(board.pieceAt(const Position(0, 0)), isNull);
      expect(board.pieceAt(const Position(1, 0)), piece('P'));
      expect(board.pieceAt(const Position(2, 0)), piece('S'));
      expect(board.pieceAt(const Position(0, 1)), isNull);
    });

    test('refill fills every empty cell deterministically', () {
      final first = boardFromNullable([
        [null, piece('P')],
        [piece('E'), null],
      ]);
      final second = first.copy();

      BoardResolver(seed: 42).refill(first);
      BoardResolver(seed: 42).refill(second);

      expect(
        first.positions.every((position) => first.pieceAt(position) != null),
        isTrue,
      );
      expect(first.toRows(), second.toRows());
    });

    test('cascades resolve to a stable board and terminate', () {
      final board = boardFrom(['PPP', 'ESC', 'CES', 'SCE']);

      final steps = BoardResolver(seed: 7).resolve(board);

      expect(steps, isNotEmpty);
      expect(steps.length, lessThan(100));
      expect(const MatchFinder().find(board), isEmpty);
    });
  });

  group('playable boards', () {
    test('1,000 seeded boards have no matches and a valid move', () {
      const finder = MatchFinder();
      const validator = MoveValidator();

      for (var seed = 0; seed < 1000; seed++) {
        final board = BoardGenerator(seed: seed).generate();
        expect(finder.find(board), isEmpty, reason: 'seed $seed has a match');
        expect(
          validator.hasValidMove(board),
          isTrue,
          reason: 'seed $seed is dead',
        );
      }
    });

    test('same seed generates the same board', () {
      final first = BoardGenerator(seed: 99).generate();
      final second = BoardGenerator(seed: 99).generate();

      expect(first.toRows(), second.toRows());
    });

    test('shuffle preserves pieces and produces a playable board', () {
      final board = boardFrom(['PESC', 'PESC', 'ESCP', 'ESCP']);
      final before = board.positions.map(board.pieceAt).toList()
        ..sort((a, b) => a!.kind.id.compareTo(b!.kind.id));

      BoardShuffler(seed: 12).shuffle(board);
      final after = board.positions.map(board.pieceAt).toList()
        ..sort((a, b) => a!.kind.id.compareTo(b!.kind.id));

      expect(after, before);
      expect(const MatchFinder().find(board), isEmpty);
      expect(const MoveValidator().hasValidMove(board), isTrue);
    });
  });
}

Board boardFrom(List<String> rows) => Board([
  for (final row in rows) [for (final symbol in row.split('')) piece(symbol)],
]);

Board boardFromNullable(List<List<Piece?>> rows) => Board(rows);

Piece piece(String symbol) => Piece(switch (symbol) {
  'P' => PieceKind.peanut,
  'E' => PieceKind.egg,
  'S' => PieceKind.sugarCrystal,
  'C' => PieceKind.caramelRibbon,
  'N' => PieceKind.coconutCream,
  'O' => PieceKind.cocoaCrumb,
  _ => throw ArgumentError.value(symbol),
});
