import 'dart:convert';

import 'package:flutter/services.dart';

import '../../game/domain/content.dart';

class BundledLevelRepository {
  const BundledLevelRepository({this.bundle});

  final AssetBundle? bundle;

  Future<LevelDefinition> load(int number) async {
    if (number < 1 || number > 10) {
      throw ContentException('Sunrise Bakery level must be 1 through 10.');
    }
    final source = await (bundle ?? rootBundle).loadString(
      'assets/levels/sunrise_bakery/level_$number.json',
    );
    final value = jsonDecode(source);
    if (value is! Map<String, Object?>) {
      throw const ContentException('Level JSON must be an object.');
    }
    return LevelDefinition.fromJson(value);
  }

  Future<List<LevelDefinition>> loadSunriseBakery() async =>
      Future.wait([for (var number = 1; number <= 10; number++) load(number)]);
}
