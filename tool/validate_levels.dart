import 'dart:convert';
import 'dart:io';

import 'package:puff_and_crunch/game/domain/match3.dart';

void main(List<String> arguments) {
  final requestedSimulations = _simulationCount(arguments);
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
  }

  for (var run = 0; run < requestedSimulations; run++) {
    final file = files[run % files.length];
    final decoded = jsonDecode(file.readAsStringSync()) as Map<String, Object?>;
    final level = LevelDefinition.fromJson(decoded);
    final blockerGrid = BlockerGrid.fromMechanics(level.blockers);
    final blocked = <Position>{...blockerGrid.blockingPositions};
    for (var row = 0; row < level.rows; row++) {
      for (var column = 0; column < level.columns; column++) {
        final cell = Position(row, column);
        if (!level.playableCells.contains(cell)) blocked.add(cell);
      }
    }
    _simulate(level, run ~/ files.length, blocked);
    simulations++;
  }
  stdout.writeln(
    'Validated 60 levels and $simulations bounded gameplay simulations.',
  );
}

int _simulationCount(List<String> arguments) {
  const option = '--simulations=';
  final value = arguments
      .where((argument) => argument.startsWith(option))
      .map((argument) => int.tryParse(argument.substring(option.length)))
      .firstOrNull;
  if (value == null &&
      arguments.any((argument) => argument.startsWith(option))) {
    throw const FormatException('--simulations must be a positive integer.');
  }
  if ((value ?? 200) < 1) {
    throw const FormatException('--simulations must be a positive integer.');
  }
  return value ?? 200;
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
