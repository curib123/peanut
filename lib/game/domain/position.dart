class Position {
  const Position(this.row, this.column);

  final int row;
  final int column;

  bool isOrthogonallyAdjacentTo(Position other) =>
      (row - other.row).abs() + (column - other.column).abs() == 1;

  @override
  bool operator ==(Object other) =>
      other is Position && row == other.row && column == other.column;

  @override
  int get hashCode => Object.hash(row, column);

  @override
  String toString() => 'Position($row, $column)';
}
