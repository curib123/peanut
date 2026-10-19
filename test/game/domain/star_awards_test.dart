import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:puff_and_crunch/game/domain/content.dart';

void main() {
  test('completed level awards use the recipe thresholds', () {
    final level = LevelDefinition.fromJson(
      jsonDecode(
            File(
              'assets/levels/sunrise_bakery/level_1.json',
            ).readAsStringSync(),
          )
          as Map<String, Object?>,
    );
    expect(level.starsForCompletedScore(2000), 1);
    expect(level.starsForCompletedScore(3000), 2);
    expect(level.starsForCompletedScore(3500), 3);
    expect(level.starsForCompletedScore(0), 1);
  });
}
