import 'dart:convert';
import 'dart:io';

const pieces = {
  'peanut': 4,
  'egg': 4,
  'sugar_crystal': 4,
  'caramel_ribbon': 4,
  'coconut_cream': 4,
  'cocoa_crumb': 4,
};

void main() {
  final output = Directory('assets/levels/sunrise_bakery')
    ..createSync(recursive: true);
  final levels = <Map<String, Object?>>[
    _level(
      1,
      18,
      1101,
      1200,
      'Swap neighboring treats to make a row of three.',
    ),
    _level(
      2,
      18,
      1102,
      1800,
      'Matches can fall into another match. Enjoy the cascade!',
    ),
    _level(
      3,
      20,
      1103,
      2200,
      'Collect both recipe ingredients before moves run out.',
      goals: [_collect('peanut', 12), _collect('egg', 12)],
    ),
    _level(
      4,
      22,
      1104,
      2600,
      'Match on Sugar Frosting to clear it.',
      goals: [_goal('clear_frosting', 6)],
      blockers: _blockers('sugar_frosting', 1, [
        [2, 2],
        [2, 3],
        [2, 4],
        [5, 3],
        [5, 4],
        [5, 5],
      ]),
    ),
    _level(5, 22, 1105, 3200, 'Match four in a line to bake a Sugar Beam.'),
    _level(
      6,
      23,
      1106,
      3600,
      'The tray has open corners. Plan around its shape.',
      playable: _withoutCorners(),
    ),
    _level(
      7,
      22,
      1107,
      4200,
      'Aim special treats at the ingredients you still need.',
      goals: [_collect('sugar_crystal', 20)],
    ),
    _level(
      8,
      24,
      1108,
      4800,
      'Double frosting needs two delicious hits.',
      goals: [_goal('clear_frosting', 8)],
      blockers: _blockers('sugar_frosting', 2, [
        [1, 2],
        [1, 3],
        [1, 4],
        [1, 5],
        [6, 2],
        [6, 3],
        [6, 4],
        [6, 5],
      ]),
    ),
    _level(
      9,
      25,
      1109,
      5500,
      'Balance the score recipe with frosting cleanup.',
      goals: [_goal('target_score', 4200), _goal('clear_frosting', 8)],
      blockers: _blockers('sugar_frosting', 1, [
        [2, 2],
        [2, 5],
        [3, 3],
        [3, 4],
        [4, 3],
        [4, 4],
        [5, 2],
        [5, 5],
      ]),
    ),
    _level(
      10,
      28,
      1110,
      7000,
      'Final bake: collect peanuts and clear every frosting layer!',
      goals: [
        _collect('peanut', 28),
        _goal('clear_frosting', 12),
        _goal('target_score', 6000),
      ],
      blockers: _blockers('sugar_frosting', 2, [
        [1, 1],
        [1, 3],
        [1, 4],
        [1, 6],
        [3, 1],
        [3, 6],
        [4, 1],
        [4, 6],
        [6, 1],
        [6, 3],
        [6, 4],
        [6, 6],
      ]),
    ),
  ];
  for (final level in levels) {
    final number = level['order'];
    File('${output.path}/level_$number.json').writeAsStringSync(
      '${const JsonEncoder.withIndent('  ').convert(level)}\n',
    );
  }
  stdout.writeln('Generated 10 Sunrise Bakery levels.');
}

Map<String, Object?> _level(
  int number,
  int moves,
  int seed,
  int score,
  String tutorial, {
  List<Map<String, Object?>>? goals,
  List<Map<String, Object?>> blockers = const [],
  List<List<int>>? playable,
}) => {
  'id': 'sunrise_$number',
  'worldId': 'sunrise_bakery',
  'order': number,
  'rows': 8,
  'columns': 8,
  'moves': moves,
  'seed': seed,
  'spawnWeights': pieces,
  'starThresholds': [score, (score * 1.45).round(), (score * 1.9).round()],
  'goals': goals ?? [_goal('target_score', score)],
  'blockers': blockers,
  'playableCells': ?playable,
  'tutorial': [
    {'message': tutorial},
  ],
  'metadata': {
    'difficulty': number,
    'name': number == 10 ? 'Sunrise Celebration' : 'Morning Recipe $number',
  },
};

Map<String, Object?> _goal(String id, int target) => {
  'id': id,
  'parameters': {'target': target},
};
Map<String, Object?> _collect(String piece, int target) => {
  'id': 'collect_pieces',
  'parameters': {'pieceId': piece, 'target': target},
};
List<Map<String, Object?>> _blockers(
  String id,
  int layers,
  List<List<int>> cells,
) => [
  for (final cell in cells)
    {
      'id': id,
      'parameters': {'layers': layers, 'row': cell[0], 'column': cell[1]},
    },
];
List<List<int>> _withoutCorners() => [
  for (var r = 0; r < 8; r++)
    for (var c = 0; c < 8; c++)
      if (!((r < 2 || r > 5) && (c < 2 || c > 5))) [r, c],
];
