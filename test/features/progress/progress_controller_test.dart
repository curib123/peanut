import 'package:flutter_test/flutter_test.dart';
import 'package:puff_and_crunch/features/progress/application/progress_controller.dart';
import 'package:puff_and_crunch/features/progress/data/save_repository.dart';
import 'package:puff_and_crunch/features/progress/domain/game_save_data.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('level completion unlocks next level and keeps best results', () async {
    final repository = MemorySaveRepository();
    final controller = ProgressController(repository);
    await controller.load();
    await controller.completeLevel(level: 1, score: 5000, stars: 2);
    await controller.completeLevel(level: 1, score: 4000, stars: 1);

    expect(controller.state.data.highestUnlockedLevel, 2);
    expect(controller.state.data.starsFor(1), 2);
    expect(controller.state.data.bestScoreFor(1), 5000);
    await expectLater(
      controller.completeLevel(level: 4, score: 1, stars: 1),
      throwsStateError,
    );
  });

  test('settings and boosters survive a controller restart', () async {
    final repository = MemorySaveRepository();
    final first = ProgressController(repository);
    await first.load();
    await first.updateSettings(
      const GameSettings(
        soundEnabled: false,
        musicEnabled: false,
        hapticsEnabled: false,
        reducedMotion: true,
      ),
    );
    await first.setBooster('event_whisk', 4);

    final restarted = ProgressController(repository);
    await restarted.load();
    expect(restarted.state.data.settings.reducedMotion, isTrue);
    expect(restarted.state.data.settings.soundEnabled, isFalse);
    expect(restarted.state.data.boosters['event_whisk'], 4);
  });

  test('version 1 data migrates and normalizes legacy values', () {
    final migrated = GameSaveData.fromJson({
      'version': 1,
      'highestUnlockedLevel': 3,
      'starsByLevel': {'1': 9},
      'bestScoreByLevel': {'1': -20},
      'soundEnabled': false,
      'reducedMotion': true,
    });

    expect(migrated.version, GameSaveData.currentVersion);
    expect(migrated.highestUnlockedLevel, 3);
    expect(migrated.starsFor(1), 3);
    expect(migrated.bestScoreFor(1), 0);
    expect(migrated.settings.soundEnabled, isFalse);
    expect(migrated.settings.reducedMotion, isTrue);
  });

  test('reset clears persisted progress', () async {
    final repository = MemorySaveRepository();
    final controller = ProgressController(repository);
    await controller.load();
    await controller.completeLevel(level: 1, score: 5000, stars: 1);
    await controller.reset();

    expect(repository.wasCleared, isTrue);
    expect(controller.state.data.highestUnlockedLevel, 1);
    expect(controller.state.data.starsByLevel, isEmpty);
  });

  test('Shared Preferences repository survives a new instance', () async {
    SharedPreferences.setMockInitialValues({});
    final first = SharedPreferencesSaveRepository();
    await first.save(
      const GameSaveData(
        highestUnlockedLevel: 4,
        settings: GameSettings(reducedMotion: true),
      ),
    );

    final restored = await SharedPreferencesSaveRepository().load();

    expect(restored.highestUnlockedLevel, 4);
    expect(restored.settings.reducedMotion, isTrue);
  });
}

class MemorySaveRepository implements SaveRepository {
  GameSaveData data = const GameSaveData();
  bool wasCleared = false;

  @override
  Future<void> clear() async {
    wasCleared = true;
    data = const GameSaveData();
  }

  @override
  Future<GameSaveData> load() async => data;

  @override
  Future<void> save(GameSaveData data) async {
    this.data = GameSaveData.fromJson(data.toJson());
  }
}
