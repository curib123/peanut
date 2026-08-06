import 'board.dart';
import 'piece.dart';
import 'position.dart';

enum MatchOrientation { horizontal, vertical, intersecting }

class MatchGroup {
  MatchGroup({required this.type, required Set<Position> positions})
    : positions = Set<Position>.unmodifiable(positions);

  final PieceKind type;
  final Set<Position> positions;

  MatchOrientation get orientation {
    final rows = positions.map((position) => position.row).toSet();
    final columns = positions.map((position) => position.column).toSet();
    if (rows.length == 1) return MatchOrientation.horizontal;
    if (columns.length == 1) return MatchOrientation.vertical;
    return MatchOrientation.intersecting;
  }
}

class MatchFinder {
  const MatchFinder();

  List<MatchGroup> find(Board board) {
    final runs = <MatchGroup>[];

    for (var row = 0; row < board.rows; row++) {
      _collectLine(
        [
          for (var column = 0; column < board.columns; column++)
            Position(row, column),
        ],
        board,
        runs,
      );
    }
    for (var column = 0; column < board.columns; column++) {
      _collectLine(
        [for (var row = 0; row < board.rows; row++) Position(row, column)],
        board,
        runs,
      );
    }

    return _mergeIntersections(runs);
  }

  void _collectLine(List<Position> line, Board board, List<MatchGroup> output) {
    var start = 0;
    while (start < line.length) {
      final piece = board.pieceAt(line[start]);
      var end = start + 1;
      while (piece != null &&
          end < line.length &&
          board.pieceAt(line[end])?.kind == piece.kind) {
        end++;
      }
      if (piece != null && end - start >= 3) {
        output.add(
          MatchGroup(
            type: piece.kind,
            positions: line.sublist(start, end).toSet(),
          ),
        );
      }
      start = end;
    }
  }

  List<MatchGroup> _mergeIntersections(List<MatchGroup> runs) {
    final merged = <MatchGroup>[];
    for (final run in runs) {
      final touching = <MatchGroup>[
        for (final group in merged)
          if (group.type == run.type &&
              group.positions.any(run.positions.contains))
            group,
      ];
      if (touching.isEmpty) {
        merged.add(run);
        continue;
      }
      final positions = <Position>{...run.positions};
      for (final group in touching) {
        positions.addAll(group.positions);
        merged.remove(group);
      }
      merged.add(MatchGroup(type: run.type, positions: positions));
    }
    return merged;
  }
}
