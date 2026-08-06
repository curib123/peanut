import 'dart:convert';

import 'package:flutter/services.dart';

import '../../game/domain/content.dart';

class BundledLevelRepository {
  const BundledLevelRepository({this.bundle});

  final AssetBundle? bundle;

  Future<LevelDefinition> load(int number) async {
    if (number < 1 || number > 60) {
      throw ContentException('Launch level must be 1 through 60.');
    }
    final world = worldForLevel(number);
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
      Future.wait([for (var number = 1; number <= 10; number++) load(number)]);

  Future<List<LevelDefinition>> loadLaunchLevels() async =>
      Future.wait([for (var number = 1; number <= 60; number++) load(number)]);

  static String worldForLevel(int number) => switch ((number - 1) ~/ 10) {
    0 => 'sunrise_bakery',
    1 => 'peanut_grove',
    2 => 'egg_cloud_kitchen',
    3 => 'sugar_harbor',
    4 => 'festival_oven',
    5 => 'starlight_bake_off',
    _ => throw ContentException('Launch level must be 1 through 60.'),
  };

  static String worldNameForLevel(int number) => switch ((number - 1) ~/ 10) {
    0 => 'Sunrise Bakery',
    1 => 'Peanut Grove',
    2 => 'Egg Cloud Kitchen',
    3 => 'Sugar Harbor',
    4 => 'Festival Oven',
    5 => 'Starlight Bake-Off',
    _ => 'New Island',
  };
}
