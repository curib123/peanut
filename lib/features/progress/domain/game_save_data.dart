class GameSettings {
  const GameSettings({
    this.soundEnabled = true,
    this.musicEnabled = true,
    this.hapticsEnabled = true,
    this.reducedMotion = false,
  });

  final bool soundEnabled;
  final bool musicEnabled;
  final bool hapticsEnabled;
  final bool reducedMotion;

  GameSettings copyWith({
    bool? soundEnabled,
    bool? musicEnabled,
    bool? hapticsEnabled,
    bool? reducedMotion,
  }) => GameSettings(
    soundEnabled: soundEnabled ?? this.soundEnabled,
    musicEnabled: musicEnabled ?? this.musicEnabled,
    hapticsEnabled: hapticsEnabled ?? this.hapticsEnabled,
    reducedMotion: reducedMotion ?? this.reducedMotion,
  );

  Map<String, Object?> toJson() => {
    'sound': soundEnabled,
    'music': musicEnabled,
    'haptics': hapticsEnabled,
    'reducedMotion': reducedMotion,
  };
}

class GameSaveData {
  static const defaultBoosters = {
    'sugar_beam': 1,
    'oven_burst': 1,
    'peanut_spinner': 1,
  };

  const GameSaveData({
    this.version = currentVersion,
    this.highestUnlockedLevel = 1,
    this.starsByLevel = const {},
    this.bestScoreByLevel = const {},
    this.boosters = defaultBoosters,
    this.settings = const GameSettings(),
  });

  static const currentVersion = 2;

  final int version;
  final int highestUnlockedLevel;
  final Map<int, int> starsByLevel;
  final Map<int, int> bestScoreByLevel;
  final Map<String, int> boosters;
  final GameSettings settings;

  int starsFor(int level) => starsByLevel[level] ?? 0;
  int bestScoreFor(int level) => bestScoreByLevel[level] ?? 0;

  GameSaveData copyWith({
    int? highestUnlockedLevel,
    Map<int, int>? starsByLevel,
    Map<int, int>? bestScoreByLevel,
    Map<String, int>? boosters,
    GameSettings? settings,
  }) => GameSaveData(
    highestUnlockedLevel: highestUnlockedLevel ?? this.highestUnlockedLevel,
    starsByLevel: starsByLevel ?? this.starsByLevel,
    bestScoreByLevel: bestScoreByLevel ?? this.bestScoreByLevel,
    boosters: boosters ?? this.boosters,
    settings: settings ?? this.settings,
  );

  Map<String, Object?> toJson() => {
    'version': currentVersion,
    'highestUnlockedLevel': highestUnlockedLevel,
    'starsByLevel': {
      for (final entry in starsByLevel.entries) '${entry.key}': entry.value,
    },
    'bestScoreByLevel': {
      for (final entry in bestScoreByLevel.entries) '${entry.key}': entry.value,
    },
    'boosters': boosters,
    'settings': settings.toJson(),
  };

  factory GameSaveData.fromJson(Map<String, Object?> json) {
    final version = _int(json['version'], fallback: 1);
    if (version > currentVersion) return const GameSaveData();
    final settingsJson = _map(json['settings']);
    final settings = GameSettings(
      soundEnabled: _bool(
        settingsJson['sound'] ?? json['soundEnabled'],
        fallback: true,
      ),
      musicEnabled: _bool(
        settingsJson['music'] ?? json['musicEnabled'],
        fallback: true,
      ),
      hapticsEnabled: _bool(
        settingsJson['haptics'] ?? json['hapticsEnabled'],
        fallback: true,
      ),
      reducedMotion: _bool(
        settingsJson['reducedMotion'] ?? json['reducedMotion'],
        fallback: false,
      ),
    );
    return GameSaveData(
      highestUnlockedLevel: _int(
        json['highestUnlockedLevel'],
        fallback: 1,
      ).clamp(1, 1000000),
      starsByLevel: _intMap(json['starsByLevel'], min: 0, max: 3),
      bestScoreByLevel: _intMap(json['bestScoreByLevel'], min: 0),
      boosters: json.containsKey('boosters')
          ? _stringIntMap(json['boosters'])
          : defaultBoosters,
      settings: settings,
    );
  }
}

Map<String, Object?> _map(Object? value) {
  if (value is! Map) return const {};
  return value.map((key, item) => MapEntry(key.toString(), item));
}

Map<int, int> _intMap(Object? value, {required int min, int? max}) {
  final result = <int, int>{};
  for (final entry in _map(value).entries) {
    final key = int.tryParse(entry.key);
    if (key == null || key < 1 || entry.value is! num) continue;
    final number = (entry.value as num).toInt();
    result[key] = number.clamp(min, max ?? 0x7fffffff);
  }
  return Map.unmodifiable(result);
}

Map<String, int> _stringIntMap(Object? value) => Map.unmodifiable({
  for (final entry in _map(value).entries)
    if (entry.value is num)
      entry.key: (entry.value as num).toInt().clamp(0, 999999),
});

int _int(Object? value, {required int fallback}) =>
    value is num ? value.toInt() : fallback;

bool _bool(Object? value, {required bool fallback}) =>
    value is bool ? value : fallback;
