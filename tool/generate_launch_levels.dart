import 'dart:convert';
import 'dart:io';

import 'package:puff_and_crunch/game/domain/match3.dart';

const _pieces = {
  'peanut': 4,
  'egg': 4,
  'sugar_crystal': 4,
  'caramel_ribbon': 4,
  'coconut_cream': 4,
  'cocoa_crumb': 4,
};

const _worlds = [
  ('sunrise_bakery', 'Sunrise Bakery'),
  ('peanut_grove', 'Peanut Grove'),
  ('egg_cloud_kitchen', 'Egg Cloud Kitchen'),
  ('sugar_harbor', 'Sugar Harbor'),
  ('festival_oven', 'Festival Oven'),
  ('starlight_bake_off', 'Starlight Bake-Off'),
];

void main() {
  final levelsRoot = Directory('assets/levels');
  for (final entry in levelsRoot.listSync(recursive: true)) {
    if (entry is File && entry.path.endsWith('.json')) entry.deleteSync();
  }
  for (var worldIndex = 0; worldIndex < _worlds.length; worldIndex++) {
    final (worldId, worldName) = _worlds[worldIndex];
    final output = Directory('assets/levels/$worldId')
      ..createSync(recursive: true);
    for (var offset = 1; offset <= 20; offset++) {
      final number = worldIndex * 20 + offset;
      final level = _buildLevel(
        number,
        worldIndex + 1,
        offset,
        worldId,
        worldName,
      );
      File('${output.path}/level_$number.json').writeAsStringSync(
        '${const JsonEncoder.withIndent('  ').convert(level)}\n',
      );
    }
  }
  stdout.writeln('Generated 120 levels across six worlds.');
}

Map<String, Object?> _buildLevel(
  int number,
  int world,
  int offset,
  String worldId,
  String worldName,
) {
  final playable = offset == 6 || (world == 6 && offset == 10)
      ? _shapedCells(world)
      : null;
  final cells = _patternCells(number, count: 4 + offset ~/ 2);
  final blockers = <Map<String, Object?>>[];
  final goals = <Map<String, Object?>>[];
  var tutorial = 'Bake a balanced recipe with careful special-piece play.';

  switch (world) {
    case 1:
      if (offset >= 5) {
        blockers.addAll(
          _blockers(
            'sugar_frosting',
            cells.take(3 + offset ~/ 3).toList(),
            layers: offset >= 15 ? 2 : 1,
          ),
        );
        goals.add(_goal('clear_frosting', 3 + offset ~/ 3));
        tutorial = 'Build cascades while clearing every frosting layer.';
      }
    case 2:
      if (offset >= 3) {
        blockers.addAll(
          _blockers(
            offset.isEven ? 'peanut_crate' : 'bakers_twine',
            cells,
            layers: offset >= 8 ? 2 : 1,
          ),
        );
        goals.add(
          _goal(
            offset.isEven ? 'break_crates' : 'collect_pieces',
            offset.isEven ? cells.length : 16 + offset,
            piece: 'peanut',
          ),
        );
        tutorial = offset.isEven
            ? 'Match beside Peanut Crates to crack them.'
            : 'Cut Baker’s Twine with a match on its treat.';
      }
    case 3:
      if (offset <= 4) {
        goals.add(
          _goal(
            'drop_recipe_baskets',
            2,
            cells: [
              [0, 2],
              [0, 5],
            ],
          ),
        );
        tutorial = 'Clear paths below the recipe baskets so they can drop.';
      } else {
        blockers.addAll(_blockers('sticky_caramel', cells));
        goals.add(
          _goal(
            'spread_cream',
            8 + offset,
            cells: [
              [3, 3],
            ],
          ),
        );
        tutorial =
            'Connect clears to Coconut Cream and spread it across the tray.';
      }
    case 4:
      blockers.addAll(
        _blockers(
          offset.isEven ? 'chocolate_crumbs' : 'sugar_frosting',
          cells,
          layers: offset >= 8 ? 2 : 1,
        ),
      );
      goals.add(
        _goal(
          offset.isEven ? 'collect_pieces' : 'clear_frosting',
          offset.isEven ? 18 + offset : cells.length,
          piece: 'sugar_crystal',
        ),
      );
      tutorial = offset.isEven
          ? 'Clear Chocolate Crumbs before they spread.'
          : 'Wash the harbor tray clean of Sugar Frosting.';
    case 5:
      if (offset >= 5) {
        blockers.addAll(
          _blockers(
            'oven_stone',
            cells.take(3).toList(),
            layers: offset >= 9 ? 2 : 1,
          ),
        );
      }
      goals.add(
        _goal(
          'light_ovens',
          3,
          cells: [
            [1, 1],
            [3, 6],
            [6, 2],
          ],
        ),
      );
      tutorial = 'Make matches on or beside each oven to light it.';
    case 6:
      blockers.addAll(
        _blockers(
          offset.isEven ? 'sugar_frosting' : 'sticky_caramel',
          cells,
          layers: offset >= 7 ? 2 : 1,
        ),
      );
      goals.add(
        _goal(
          'collect_pieces',
          20 + offset,
          piece: offset.isEven ? 'cocoa_crumb' : 'caramel_ribbon',
        ),
      );
      if (offset >= 4) goals.add(_goal('target_score', 3800 + offset * 300));
      if (offset >= 7) goals.add(_goal('clear_frosting', cells.length));
      tutorial = 'Combine specials to finish several finale goals together.';
  }
  if (goals.isEmpty) goals.add(_goal('target_score', 1800 + number * 90));

  final hardCells = blockers
      .where(
        (item) => item['id'] == 'peanut_crate' || item['id'] == 'oven_stone',
      )
      .map((item) {
        final parameters = item['parameters']! as Map<String, Object?>;
        return Position(
          parameters['row']! as int,
          parameters['column']! as int,
        );
      })
      .toSet();
  final seed = _findPlayableSeed(2000 + number * 17, playable, hardCells);
  final baseScore = 1800 + number * 75;
  final timeLimit = offset >= 11
      ? (165 - world * 5 - (offset - 11) * 4).clamp(85, 160)
      : null;
  return {
    'id': '${worldId}_$offset',
    'worldId': worldId,
    'order': number,
    'rows': 8,
    'columns': 8,
    'moves': (26 + world - offset ~/ 4).clamp(18, 28),
    'timeLimitSeconds': ?timeLimit,
    'seed': seed,
    'spawnWeights': _pieces,
    'starThresholds': [
      baseScore,
      (baseScore * 1.4).round(),
      (baseScore * 1.85).round(),
    ],
    'goals': goals,
    'blockers': blockers,
    'playableCells': ?playable,
    'tutorial': [
      {'message': tutorial},
    ],
    'metadata': {
      'difficulty': number,
      'name': '$worldName Recipe $offset',
      'simulationTier': offset >= 16 ? 'milestone' : 'standard',
      'challenge': timeLimit == null ? 'moves' : 'time_trial',
    },
  };
}

Map<String, Object?> _goal(
  String id,
  int target, {
  String? piece,
  List<List<int>>? cells,
}) => {
  'id': id,
  'parameters': {'target': target, 'pieceId': ?piece, 'cells': ?cells},
};
List<Map<String, Object?>> _blockers(
  String id,
  List<List<int>> cells, {
  int layers = 1,
}) => [
  for (final cell in cells)
    {
      'id': id,
      'parameters': {'row': cell[0], 'column': cell[1], 'layers': layers},
    },
];

List<List<int>> _patternCells(int seed, {required int count}) => [
  for (var index = 0; index < count; index++)
    [1 + ((seed + index * 7) % 36) ~/ 6, 1 + (seed + index * 7) % 6],
];
List<List<int>> _shapedCells(int world) => [
  for (var row = 0; row < 8; row++)
    for (var column = 0; column < 8; column++)
      if (!((row == 0 || row == 7) && (column + world).isEven)) [row, column],
];

int _findPlayableSeed(
  int start,
  List<List<int>>? playable,
  Set<Position> hardCells,
) {
  final allowed = playable?.map((cell) => Position(cell[0], cell[1])).toSet();
  for (var seed = start; seed < start + 1000; seed++) {
    final board = BoardGenerator(seed: seed).generate();
    for (final position in board.positions) {
      if ((allowed != null && !allowed.contains(position)) ||
          hardCells.contains(position)) {
        board.setPiece(position, null);
      }
    }
    if (const MatchFinder().find(board).isEmpty &&
        const MoveValidator().hasValidMove(board)) {
      return seed;
    }
  }
  throw StateError('Unable to find a playable seed from $start.');
}
