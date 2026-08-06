import 'package:flutter_test/flutter_test.dart' hide MatchFinder;
import 'package:puff_and_crunch/game/domain/match3.dart';

void main() {
  test('content pack adds a world and level without engine changes', () {
    final catalog = GameContentCatalog.fromJson({
      'schemaVersion': 1,
      'worlds': [world('sunrise', 1)],
      'levels': [level('sunrise-1', 'sunrise', 1)],
      'events': <Object?>[],
    });
    final snapshot = catalog.snapshotAt(DateTime.utc(2026));
    final definition = snapshot.level('sunrise-1');
    final board = BoardGenerator(
      seed: definition.seed,
      pieceTypes: definition.spawnPool,
    ).generate(rows: definition.rows, columns: definition.columns);

    expect(snapshot.worlds.single.id, 'sunrise');
    expect(board.rows, 8);
    expect(board.columns, 8);
    expect(const MatchFinder().find(board), isEmpty);
    expect(const MoveValidator().hasValidMove(board), isTrue);
  });

  test('custom event pieces are identified by data-driven string IDs', () {
    final definition = LevelDefinition.fromJson(
      level('festival-1', 'festival', 1, customPiece: 'mango_macaron'),
    );

    expect(
      definition.spawnWeights.keys,
      contains(const PieceKind('mango_macaron')),
    );
  });

  test(
    'active events add content and modifiers only during their schedule',
    () {
      final catalog = GameContentCatalog.fromJson({
        'schemaVersion': 1,
        'worlds': [world('sunrise', 1)],
        'levels': [level('sunrise-1', 'sunrise', 1)],
        'events': [
          {
            'id': 'summer-2026',
            'name': 'Summer Bake-Off',
            'startsAt': '2026-07-01T00:00:00Z',
            'endsAt': '2026-09-01T00:00:00Z',
            'worlds': [world('summer-island', 100)],
            'levels': [level('summer-1', 'summer-island', 100)],
            'modifiers': [
              {
                'id': 'double_cascade_score',
                'parameters': {'multiplier': 2},
              },
            ],
          },
        ],
      });

      final active = catalog.snapshotAt(DateTime.utc(2026, 8, 1));
      final inactive = catalog.snapshotAt(DateTime.utc(2026, 10, 1));

      expect(active.worlds.map((item) => item.id), contains('summer-island'));
      expect(active.levels.map((item) => item.id), contains('summer-1'));
      expect(active.events.single.modifiers.single.id, 'double_cascade_score');
      expect(inactive.events, isEmpty);
      expect(
        inactive.worlds.map((item) => item.id),
        isNot(contains('summer-island')),
      );
    },
  );

  test('invalid references and duplicate IDs are rejected', () {
    expect(
      () => GameContentCatalog.fromJson({
        'schemaVersion': 1,
        'worlds': [world('sunrise', 1), world('sunrise', 2)],
        'levels': <Object?>[],
        'events': <Object?>[],
      }),
      throwsA(isA<ContentException>()),
    );
    expect(
      () => GameContentCatalog.fromJson({
        'schemaVersion': 1,
        'worlds': [world('sunrise', 1)],
        'levels': [level('lost-1', 'missing', 1)],
        'events': <Object?>[],
      }),
      throwsA(isA<ContentException>()),
    );
  });
}

Map<String, Object?> world(String id, int order) => {
  'id': id,
  'name': id,
  'order': order,
  'themeId': '${id}_theme',
};

Map<String, Object?> level(
  String id,
  String worldId,
  int order, {
  String customPiece = 'cocoa_crumb',
}) => {
  'id': id,
  'worldId': worldId,
  'order': order,
  'rows': 8,
  'columns': 8,
  'moves': 20,
  'seed': order,
  'spawnWeights': {'peanut': 2, 'egg': 2, 'sugar_crystal': 2, customPiece: 1},
  'starThresholds': [1000, 2000, 3000],
  'goals': [
    {
      'id': 'target_score',
      'parameters': {'score': 1000},
    },
  ],
  'blockers': <Object?>[],
};
