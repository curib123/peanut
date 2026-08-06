import 'dart:convert';
import 'dart:io';

import 'package:puff_and_crunch/game/domain/match3.dart';

void main() {
  final files =
      Directory('assets/levels')
          .listSync(recursive: true)
          .whereType<File>()
          .where((file) => file.path.endsWith('.json'))
          .toList()
        ..sort((a, b) => _number(a).compareTo(_number(b)));
  if (files.length != 60) {
    throw StateError('Expected 60 levels, found ${files.length}.');
  }

  var simulations = 0;
  for (final file in files) {
    final decoded = jsonDecode(file.readAsStringSync());
    if (decoded is! Map<String, Object?>) {
      throw FormatException('Invalid object: ${file.path}');
    }
    final level = LevelDefinition.fromJson(decoded);
    if (level.order != _number(file)) {
      throw StateError('${level.id} order/file mismatch.');
    }
    if (level.tutorial.isEmpty) {
      throw StateError('${level.id} has no tutorial.');
    }
    for (final goal in level.goals) {
      GoalState.fromMechanic(goal);
    }
    final blockerGrid = BlockerGrid.fromMechanics(level.blockers);
    final board = BoardGenerator(
      seed: level.seed,
      pieceTypes: level.spawnPool,
    ).generate(rows: level.rows, columns: level.columns);
    final blocked = <Position>{...blockerGrid.blockingPositions};
    for (final cell in board.positions.where(
      (cell) => !level.playableCells.contains(cell),
    )) {
      blocked.add(cell);
    }
    for (final cell in blocked) {
      board.setPiece(cell, null);
    }
    if (const MatchFinder().find(board).isNotEmpty) {
      throw StateError('${level.id} opens with a match.');
    }
    if (_validSwap(board, blocked) == null) {
      throw StateError('${level.id} opens without a move.');
    }

    if (level.order >= 11) {
      for (var run = 0; run < 4; run++) {
        _simulate(level, run, blocked);
        simulations++;
      }
    }
  }
  stdout.writeln(
    'Validated 60 levels and $simulations bounded gameplay simulations.',
  );
}

void _simulate(LevelDefinition level, int run, Set<Position> blocked) {
  final board = BoardGenerator(
    seed: level.seed + run * 10000,
    pieceTypes: level.spawnPool,
  ).generate(rows: level.rows, columns: level.columns);
  for (final cell in blocked) {
    board.setPiece(cell, null);
  }
  final engine = TurnEngine(
    resolver: BoardResolver(seed: level.seed + run * 31 + 1),
    shuffler: BoardShuffler(seed: level.seed + run * 31 + 2),
  );
  for (var turn = 0; turn < 8; turn++) {
    final swap = _validSwap(board, blocked);
    if (swap == null) break;
    final result = engine.resolveSwap(
      board,
      swap.$1,
      swap.$2,
      blockedCells: blocked,
    );
    if (!result.isValid || result.cascades.length > 100) {
      throw StateError('${level.id} simulation failed.');
    }
    if (const MatchFinder().find(board).isNotEmpty) {
      throw StateError('${level.id} simulation left a match.');
    }
  }
}

(Position, Position)? _validSwap(Board board, Set<Position> blocked) {
  const validator = MoveValidator();
  for (final first in board.positions) {
    if (blocked.contains(first)) continue;
    for (final second in [
      Position(first.row, first.column + 1),
      Position(first.row + 1, first.column),
    ]) {
      if (!blocked.contains(second) &&
          board.contains(second) &&
          validator.isValidSwap(board, first, second)) {
        return (first, second);
      }
    }
  }
  return null;
}

int _number(File file) =>
    int.parse(RegExp(r'level_(\d+)\.json').firstMatch(file.path)!.group(1)!);
