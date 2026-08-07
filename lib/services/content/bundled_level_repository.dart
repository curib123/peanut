import 'dart:convert';

import 'package:flutter/services.dart';

import '../../game/domain/content.dart';
import 'world_presentation_catalog.dart';

class BundledLevelRepository {
  const BundledLevelRepository({this.bundle});

  final AssetBundle? bundle;

  Future<LevelDefinition> load(int number) async {
    if (number < 1) throw ContentException('Level number must be positive.');
    final world = (await WorldPresentationCatalog.load(
      bundle: bundle,
    )).worldForLevel(number).id;
    final source = await (bundle ?? rootBundle).loadString(
      'assets/levels/$world/level_$number.json',
    );
    final value = jsonDecode(source);
    if (value is! Map<String, Object?>) {
      throw const ContentException('Level JSON must be an object.');
    }
    return LevelDefinition.fromJson(value);
  }

  Future<List<LevelDefinition>> loadSunriseBakery() async =>
      Future.wait([for (var number = 1; number <= 20; number++) load(number)]);

  Future<List<LevelDefinition>> loadLaunchLevels() async =>
      Future.wait([for (var number = 1; number <= 120; number++) load(number)]);
}
