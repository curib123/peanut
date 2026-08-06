import 'piece.dart';
import 'position.dart';

class Board {
  Board(List<List<Piece?>> cells)
    : assert(cells.isNotEmpty),
      assert(cells.first.isNotEmpty),
      assert(cells.every((row) => row.length == cells.first.length)),
      _cells = [for (final row in cells) List<Piece?>.from(row)];

  factory Board.filled(int rows, int columns, Piece piece) => Board([
    for (var row = 0; row < rows; row++) List<Piece?>.filled(columns, piece),
  ]);

  final List<List<Piece?>> _cells;

  int get rows => _cells.length;
  int get columns => _cells.first.length;

  Piece? pieceAt(Position position) {
    _checkBounds(position);
    return _cells[position.row][position.column];
  }

  void setPiece(Position position, Piece? piece) {
    _checkBounds(position);
    _cells[position.row][position.column] = piece;
  }

  void swap(Position first, Position second) {
    _checkBounds(first);
    _checkBounds(second);
    final held = pieceAt(first);
    setPiece(first, pieceAt(second));
    setPiece(second, held);
  }

  bool contains(Position position) =>
      position.row >= 0 &&
      position.row < rows &&
      position.column >= 0 &&
      position.column < columns;

  Iterable<Position> get positions sync* {
    for (var row = 0; row < rows; row++) {
      for (var column = 0; column < columns; column++) {
        yield Position(row, column);
      }
    }
  }

  Board copy() => Board(_cells);

  List<List<Piece?>> toRows() => [
    for (final row in _cells) List<Piece?>.unmodifiable(row),
  ];

  void _checkBounds(Position position) {
    if (!contains(position)) {
      throw RangeError('Position is outside this board: $position');
    }
  }
}
