import 'dart:convert';

import 'package:flutter/services.dart';

class WorldPresentation {
  const WorldPresentation({
    required this.id,
    required this.name,
    required this.order,
    required this.firstLevel,
    required this.lastLevel,
    required this.backgroundAsset,
    required this.musicAsset,
  });

  factory WorldPresentation.fromJson(Map<String, Object?> json) =>
      WorldPresentation(
        id: _string(json, 'id'),
        name: _string(json, 'name'),
        order: _integer(json, 'order'),
        firstLevel: _integer(json, 'firstLevel'),
        lastLevel: _integer(json, 'lastLevel'),
        backgroundAsset: _string(json, 'backgroundAsset'),
        musicAsset: _string(json, 'musicAsset'),
      );

  final String id;
  final String name;
  final int order;
  final int firstLevel;
  final int lastLevel;
  final String backgroundAsset;
  final String musicAsset;
}

class MainPresentation {
  const MainPresentation({
    required this.backgroundAsset,
    required this.musicAsset,
  });

  final String backgroundAsset;
  final String musicAsset;
}

class WorldPresentationCatalog {
  WorldPresentationCatalog({
    required this.main,
    required List<WorldPresentation> worlds,
  }) : worlds = List.unmodifiable(worlds),
       _byId = Map.unmodifiable({for (final world in worlds) world.id: world}) {
    if (_byId.length != worlds.length) {
      throw const FormatException('World presentation IDs must be unique.');
    }
  }

  final MainPresentation main;
  final List<WorldPresentation> worlds;
  final Map<String, WorldPresentation> _byId;

  WorldPresentation world(String id) {
    final value = _byId[id];
    if (value == null) throw FormatException('Missing world presentation: $id');
    return value;
  }

  WorldPresentation worldForLevel(int level) => worlds.firstWhere(
    (world) => level >= world.firstLevel && level <= world.lastLevel,
    orElse: () =>
        throw FormatException('No world presentation contains level $level.'),
  );

  int get lastLevel => worlds.fold(
    0,
    (value, world) => world.lastLevel > value ? world.lastLevel : value,
  );

  static WorldPresentationCatalog? _resolved;
  static Future<WorldPresentationCatalog>? _inFlight;

  static Future<WorldPresentationCatalog> load({AssetBundle? bundle}) {
    if (bundle != null) return _load(bundle);
    final resolved = _resolved;
    if (resolved != null) return Future.value(resolved);
    return _inFlight ??= _load(rootBundle).then((catalog) {
      _resolved = catalog;
      _inFlight = null;
      return catalog;
    });
  }

  static Future<WorldPresentationCatalog> _load(AssetBundle bundle) async {
    final decoded = jsonDecode(
      await bundle.loadString('assets/content/worlds.json'),
    );
    if (decoded is! Map<String, Object?> || decoded['schemaVersion'] != 1) {
      throw const FormatException('Unsupported world presentation catalog.');
    }
    final mainJson = _map(decoded['main'], 'main');
    final rawWorlds = decoded['worlds'];
    if (rawWorlds is! List<Object?>) {
      throw const FormatException('worlds must be a list.');
    }
    final worlds =
        rawWorlds
            .map((value) => WorldPresentation.fromJson(_map(value, 'world')))
            .toList()
          ..sort((a, b) => a.order.compareTo(b.order));
    return WorldPresentationCatalog(
      main: MainPresentation(
        backgroundAsset: _string(mainJson, 'backgroundAsset'),
        musicAsset: _string(mainJson, 'musicAsset'),
      ),
      worlds: worlds,
    );
  }
}

Map<String, Object?> _map(Object? value, String label) {
  if (value is! Map) throw FormatException('$label must be an object.');
  return value.map((key, item) => MapEntry(key.toString(), item));
}

String _string(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value is! String || value.isEmpty) {
    throw FormatException('$key must be a non-empty string.');
  }
  return value;
}

int _integer(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value is! int) throw FormatException('$key must be an integer.');
  return value;
}
