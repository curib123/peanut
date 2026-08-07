import 'piece.dart';
import 'position.dart';

class ContentException implements Exception {
  const ContentException(this.message);

  final String message;

  @override
  String toString() => 'ContentException: $message';
}

class MechanicDefinition {
  MechanicDefinition({
    required this.id,
    Map<String, Object?> parameters = const {},
  }) : parameters = Map.unmodifiable(parameters);

  factory MechanicDefinition.fromJson(Map<String, Object?> json) {
    return MechanicDefinition(
      id: _requiredString(json, 'id'),
      parameters: _objectMap(json['parameters'], 'mechanic parameters'),
    );
  }

  final String id;
  final Map<String, Object?> parameters;
}

class LevelDefinition {
  LevelDefinition({
    required this.id,
    required this.worldId,
    required this.order,
    required this.rows,
    required this.columns,
    required this.moves,
    this.timeLimitSeconds,
    required this.seed,
    required Map<PieceKind, int> spawnWeights,
    required List<int> starThresholds,
    List<MechanicDefinition> goals = const [],
    List<MechanicDefinition> blockers = const [],
    Set<Position>? playableCells,
    List<TutorialStep> tutorial = const [],
    Map<String, Object?> metadata = const {},
  }) : spawnWeights = Map.unmodifiable(spawnWeights),
       starThresholds = List.unmodifiable(starThresholds),
       goals = List.unmodifiable(goals),
       blockers = List.unmodifiable(blockers),
       playableCells = Set.unmodifiable(
         playableCells ??
             {
               for (var row = 0; row < rows; row++)
                 for (var column = 0; column < columns; column++)
                   Position(row, column),
             },
       ),
       tutorial = List.unmodifiable(tutorial),
       metadata = Map.unmodifiable(metadata) {
    if (rows < 3 || columns < 3) {
      throw ContentException('Level $id must be at least 3x3.');
    }
    if (moves < 1) throw ContentException('Level $id must have moves.');
    if (timeLimitSeconds != null && timeLimitSeconds! < 10) {
      throw ContentException('Level $id time limit is too short.');
    }
    if (spawnWeights.length < 3 ||
        spawnWeights.values.any((weight) => weight < 1)) {
      throw ContentException(
        'Level $id needs at least three positive spawn weights.',
      );
    }
    if (starThresholds.length != 3 ||
        starThresholds[0] <= 0 ||
        starThresholds[0] >= starThresholds[1] ||
        starThresholds[1] >= starThresholds[2]) {
      throw ContentException(
        'Level $id needs three ascending star thresholds.',
      );
    }
    if (this.playableCells.length < 9 ||
        this.playableCells.any(
          (cell) =>
              cell.row < 0 ||
              cell.row >= rows ||
              cell.column < 0 ||
              cell.column >= columns,
        )) {
      throw ContentException('Level $id has invalid playable cells.');
    }
  }

  factory LevelDefinition.fromJson(Map<String, Object?> json) {
    final rawWeights = _objectMap(json['spawnWeights'], 'spawnWeights');
    return LevelDefinition(
      id: _requiredString(json, 'id'),
      worldId: _requiredString(json, 'worldId'),
      order: _requiredInt(json, 'order'),
      rows: _requiredInt(json, 'rows'),
      columns: _requiredInt(json, 'columns'),
      moves: _requiredInt(json, 'moves'),
      timeLimitSeconds: json['timeLimitSeconds'] == null
          ? null
          : _asInt(json['timeLimitSeconds'], 'timeLimitSeconds'),
      seed: _requiredInt(json, 'seed'),
      spawnWeights: {
        for (final entry in rawWeights.entries)
          PieceKind(entry.key): _asInt(
            entry.value,
            'spawn weight ${entry.key}',
          ),
      },
      starThresholds: _list(
        json['starThresholds'],
        'starThresholds',
      ).map((value) => _asInt(value, 'star threshold')).toList(),
      goals: _mechanics(json['goals'], 'goals'),
      blockers: _mechanics(json['blockers'], 'blockers'),
      playableCells: _positions(json['playableCells'], 'playableCells'),
      tutorial: _maps(
        json['tutorial'],
        'tutorial',
      ).map(TutorialStep.fromJson).toList(),
      metadata: _objectMap(json['metadata'], 'metadata'),
    );
  }

  final String id;
  final String worldId;
  final int order;
  final int rows;
  final int columns;
  final int moves;
  final int? timeLimitSeconds;
  final int seed;
  final Map<PieceKind, int> spawnWeights;
  final List<int> starThresholds;
  final List<MechanicDefinition> goals;
  final List<MechanicDefinition> blockers;
  final Set<Position> playableCells;
  final List<TutorialStep> tutorial;
  final Map<String, Object?> metadata;

  List<PieceKind> get spawnPool => [
    for (final entry in spawnWeights.entries)
      for (var count = 0; count < entry.value; count++) entry.key,
  ];
}

class TutorialStep {
  const TutorialStep({required this.message, this.from, this.to});

  factory TutorialStep.fromJson(Map<String, Object?> json) => TutorialStep(
    message: _requiredString(json, 'message'),
    from: _optionalPosition(json['from'], 'tutorial from'),
    to: _optionalPosition(json['to'], 'tutorial to'),
  );

  final String message;
  final Position? from;
  final Position? to;
}

class WorldDefinition {
  WorldDefinition({
    required this.id,
    required this.name,
    required this.order,
    required this.themeId,
    Map<String, Object?> metadata = const {},
  }) : metadata = Map.unmodifiable(metadata);

  factory WorldDefinition.fromJson(Map<String, Object?> json) =>
      WorldDefinition(
        id: _requiredString(json, 'id'),
        name: _requiredString(json, 'name'),
        order: _requiredInt(json, 'order'),
        themeId: _requiredString(json, 'themeId'),
        metadata: _objectMap(json['metadata'], 'metadata'),
      );

  final String id;
  final String name;
  final int order;
  final String themeId;
  final Map<String, Object?> metadata;
}

class EventDefinition {
  EventDefinition({
    required this.id,
    required this.name,
    required this.startsAt,
    required this.endsAt,
    required this.worlds,
    required this.levels,
    List<MechanicDefinition> modifiers = const [],
  }) : modifiers = List.unmodifiable(modifiers) {
    if (!endsAt.isAfter(startsAt)) {
      throw ContentException('Event $id must end after it starts.');
    }
  }

  factory EventDefinition.fromJson(Map<String, Object?> json) =>
      EventDefinition(
        id: _requiredString(json, 'id'),
        name: _requiredString(json, 'name'),
        startsAt: _requiredDate(json, 'startsAt'),
        endsAt: _requiredDate(json, 'endsAt'),
        worlds: _maps(
          json['worlds'],
          'event worlds',
        ).map(WorldDefinition.fromJson).toList(),
        levels: _maps(
          json['levels'],
          'event levels',
        ).map(LevelDefinition.fromJson).toList(),
        modifiers: _mechanics(json['modifiers'], 'event modifiers'),
      );

  final String id;
  final String name;
  final DateTime startsAt;
  final DateTime endsAt;
  final List<WorldDefinition> worlds;
  final List<LevelDefinition> levels;
  final List<MechanicDefinition> modifiers;

  bool isActiveAt(DateTime time) =>
      !time.isBefore(startsAt) && time.isBefore(endsAt);
}

class ContentSnapshot {
  ContentSnapshot({
    required this.worlds,
    required this.levels,
    required this.events,
  });

  final List<WorldDefinition> worlds;
  final List<LevelDefinition> levels;
  final List<EventDefinition> events;

  LevelDefinition level(String id) => levels.firstWhere(
    (level) => level.id == id,
    orElse: () => throw ContentException('Unknown level: $id'),
  );
}

class GameContentCatalog {
  GameContentCatalog({
    required this.schemaVersion,
    required this.worlds,
    required this.levels,
    required this.events,
  }) {
    if (schemaVersion != 1) {
      throw ContentException('Unsupported content schema: $schemaVersion');
    }
    _validateUnique('world', worlds.map((world) => world.id));
    _validateUnique('level', levels.map((level) => level.id));
    _validateUnique('event', events.map((event) => event.id));
    _validateReferences(
      worlds.map((world) => world.id).toSet(),
      levels,
      'base content',
    );
    for (final event in events) {
      _validateUnique('event world', event.worlds.map((world) => world.id));
      _validateUnique('event level', event.levels.map((level) => level.id));
      _validateReferences(
        {
          ...worlds.map((world) => world.id),
          ...event.worlds.map((world) => world.id),
        },
        event.levels,
        'event ${event.id}',
      );
    }
  }

  factory GameContentCatalog.fromJson(Map<String, Object?> json) =>
      GameContentCatalog(
        schemaVersion: _requiredInt(json, 'schemaVersion'),
        worlds: _maps(
          json['worlds'],
          'worlds',
        ).map(WorldDefinition.fromJson).toList(),
        levels: _maps(
          json['levels'],
          'levels',
        ).map(LevelDefinition.fromJson).toList(),
        events: _maps(
          json['events'],
          'events',
        ).map(EventDefinition.fromJson).toList(),
      );

  final int schemaVersion;
  final List<WorldDefinition> worlds;
  final List<LevelDefinition> levels;
  final List<EventDefinition> events;

  ContentSnapshot snapshotAt(DateTime time) {
    final activeEvents = events
        .where((event) => event.isActiveAt(time))
        .toList();
    final resolvedWorlds = [
      ...worlds,
      for (final event in activeEvents) ...event.worlds,
    ];
    final resolvedLevels = [
      ...levels,
      for (final event in activeEvents) ...event.levels,
    ];
    _validateUnique('resolved world', resolvedWorlds.map((world) => world.id));
    _validateUnique('resolved level', resolvedLevels.map((level) => level.id));
    return ContentSnapshot(
      worlds: List.unmodifiable(
        resolvedWorlds..sort((a, b) => a.order.compareTo(b.order)),
      ),
      levels: List.unmodifiable(
        resolvedLevels..sort((a, b) => a.order.compareTo(b.order)),
      ),
      events: List.unmodifiable(activeEvents),
    );
  }
}

void _validateReferences(
  Set<String> worldIds,
  List<LevelDefinition> levels,
  String scope,
) {
  for (final level in levels) {
    if (!worldIds.contains(level.worldId)) {
      throw ContentException(
        'Level ${level.id} references an unknown world in $scope.',
      );
    }
  }
}

void _validateUnique(String label, Iterable<String> ids) {
  final seen = <String>{};
  for (final id in ids) {
    if (id.isEmpty || !seen.add(id)) {
      throw ContentException('Duplicate or empty $label id: $id');
    }
  }
}

List<MechanicDefinition> _mechanics(Object? value, String label) =>
    _maps(value, label).map(MechanicDefinition.fromJson).toList();

List<Map<String, Object?>> _maps(Object? value, String label) =>
    _list(value, label).map((item) => _objectMap(item, label)).toList();

List<Object?> _list(Object? value, String label) {
  if (value == null) return const [];
  if (value is! List<Object?>) throw ContentException('$label must be a list.');
  return value;
}

Map<String, Object?> _objectMap(Object? value, String label) {
  if (value == null) return const {};
  if (value is! Map) throw ContentException('$label must be an object.');
  return value.map((key, item) => MapEntry(key.toString(), item));
}

Set<Position>? _positions(Object? value, String label) {
  if (value == null) return null;
  return _list(
    value,
    label,
  ).map((item) => _requiredPosition(item, label)).toSet();
}

Position? _optionalPosition(Object? value, String label) =>
    value == null ? null : _requiredPosition(value, label);

Position _requiredPosition(Object? value, String label) {
  final values = _list(value, label);
  if (values.length != 2) {
    throw ContentException('$label must be [row, column].');
  }
  return Position(_asInt(values[0], label), _asInt(values[1], label));
}

String _requiredString(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value is! String || value.isEmpty) {
    throw ContentException('$key must be a string.');
  }
  return value;
}

int _requiredInt(Map<String, Object?> json, String key) =>
    _asInt(json[key], key);

int _asInt(Object? value, String label) {
  if (value is! int) throw ContentException('$label must be an integer.');
  return value;
}

DateTime _requiredDate(Map<String, Object?> json, String key) {
  final source = _requiredString(json, key);
  final date = DateTime.tryParse(source);
  if (date == null) throw ContentException('$key must be an ISO-8601 date.');
  return date.toUtc();
}
