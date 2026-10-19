import 'board.dart';
import 'content.dart';
import 'position.dart';

enum BlockerKind {
  sugarFrosting,
  peanutCrate,
  stickyCaramel,
  chocolateCrumbs,
  ovenStone,
  bakersTwine,
}

class BlockerState {
  const BlockerState(this.kind, {this.layers = 1}) : assert(layers > 0);

  final BlockerKind kind;
  final int layers;

  BlockerState damage() => BlockerState(kind, layers: layers - 1);
}

class BlockerImpact {
  BlockerImpact({required this.damaged, required this.removed});

  final Set<Position> damaged;
  final Map<BlockerKind, int> removed;
}

class BlockerGrid {
  BlockerGrid([Map<Position, BlockerState> blockers = const {}])
    : _blockers = Map.of(blockers);

  final Map<Position, BlockerState> _blockers;
  bool _chocolateDamagedThisTurn = false;

  factory BlockerGrid.fromMechanics(List<MechanicDefinition> definitions) {
    final blockers = <Position, BlockerState>{};
    for (final definition in definitions) {
      final kind = switch (definition.id) {
        'sugar_frosting' => BlockerKind.sugarFrosting,
        'peanut_crate' => BlockerKind.peanutCrate,
        'sticky_caramel' => BlockerKind.stickyCaramel,
        'chocolate_crumbs' => BlockerKind.chocolateCrumbs,
        'oven_stone' => BlockerKind.ovenStone,
        'bakers_twine' => BlockerKind.bakersTwine,
        _ => throw ContentException(
          'Unknown blocker mechanic: ${definition.id}',
        ),
      };
      final row = definition.parameters['row'];
      final column = definition.parameters['column'];
      final layers = definition.parameters['layers'] ?? 1;
      if (row is! int || column is! int || layers is! int || layers < 1) {
        throw ContentException(
          'Blocker ${definition.id} has invalid position or layers.',
        );
      }
      final position = Position(row, column);
      if (blockers.containsKey(position)) {
        throw ContentException('Multiple blockers occupy $position.');
      }
      blockers[position] = BlockerState(kind, layers: layers);
    }
    return BlockerGrid(blockers);
  }

  Map<Position, BlockerState> get states => Map.unmodifiable(_blockers);

  Set<Position> get blockingPositions => {
    for (final position in _blockers.keys)
      if (blocksCell(position)) position,
  };

  Set<Position> get lockedPositions => {
    for (final position in _blockers.keys)
      if (locksSwap(position)) position,
  };

  BlockerState? at(Position position) => _blockers[position];

  bool blocksCell(Position position) => switch (_blockers[position]?.kind) {
    BlockerKind.peanutCrate || BlockerKind.ovenStone => true,
    _ => false,
  };

  bool locksSwap(Position position) => switch (_blockers[position]?.kind) {
    BlockerKind.stickyCaramel || BlockerKind.bakersTwine => true,
    _ => false,
  };

  BlockerImpact resolveClear(
    Board board,
    Set<Position> cleared, {
    required bool isSpecialClear,
  }) {
    final hits = <Position>{};
    for (final entry in _blockers.entries) {
      final direct = cleared.contains(entry.key);
      final adjacent = cleared.any(entry.key.isOrthogonallyAdjacentTo);
      final shouldHit = switch (entry.value.kind) {
        BlockerKind.peanutCrate => adjacent || (isSpecialClear && direct),
        BlockerKind.ovenStone => adjacent || (isSpecialClear && direct),
        _ => direct,
      };
      if (shouldHit && board.contains(entry.key)) hits.add(entry.key);
    }

    final removed = <BlockerKind, int>{};
    for (final position in hits) {
      final current = _blockers[position]!;
      if (current.kind == BlockerKind.chocolateCrumbs) {
        _chocolateDamagedThisTurn = true;
      }
      if (current.layers == 1) {
        _blockers.remove(position);
        removed.update(current.kind, (count) => count + 1, ifAbsent: () => 1);
      } else {
        _blockers[position] = current.damage();
      }
    }
    return BlockerImpact(
      damaged: Set.unmodifiable(hits),
      removed: Map.unmodifiable(removed),
    );
  }

  Position? endTurnChocolateSpread(Board board) {
    if (_chocolateDamagedThisTurn) {
      _chocolateDamagedThisTurn = false;
      return null;
    }
    final chocolate = _blockers.entries
        .where((entry) => entry.value.kind == BlockerKind.chocolateCrumbs)
        .map((entry) => entry.key)
        .toList();
    for (final origin in chocolate) {
      for (final target in _neighbors(origin)) {
        if (board.contains(target) && !_blockers.containsKey(target)) {
          _blockers[target] = const BlockerState(BlockerKind.chocolateCrumbs);
          return target;
        }
      }
    }
    return null;
  }

  Iterable<Position> _neighbors(Position origin) sync* {
    yield Position(origin.row - 1, origin.column);
    yield Position(origin.row, origin.column - 1);
    yield Position(origin.row, origin.column + 1);
    yield Position(origin.row + 1, origin.column);
  }
}
