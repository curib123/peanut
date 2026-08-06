import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/save_repository.dart';
import '../domain/game_save_data.dart';

class ProgressState {
  const ProgressState({
    this.isLoaded = false,
    this.data = const GameSaveData(),
  });

  final bool isLoaded;
  final GameSaveData data;
}

final saveRepositoryProvider = Provider<SaveRepository>(
  (ref) => SharedPreferencesSaveRepository(),
);

final progressControllerProvider =
    StateNotifierProvider<ProgressController, ProgressState>((ref) {
      final controller = ProgressController(ref.watch(saveRepositoryProvider));
      controller.load();
      return controller;
    });

class ProgressController extends StateNotifier<ProgressState> {
  ProgressController(this._repository) : super(const ProgressState());

  final SaveRepository _repository;

  Future<void> load() async {
    state = ProgressState(isLoaded: true, data: await _repository.load());
  }

  Future<void> completeLevel({
    required int level,
    required int score,
    required int stars,
  }) async {
    final current = state.data;
    if (level > current.highestUnlockedLevel) {
      throw StateError('Level $level is locked.');
    }
    final nextStars = {...current.starsByLevel};
    final nextScores = {...current.bestScoreByLevel};
    nextStars[level] = stars.clamp(1, 3) > current.starsFor(level)
        ? stars.clamp(1, 3)
        : current.starsFor(level);
    if (score > current.bestScoreFor(level)) nextScores[level] = score;
    await _replace(
      current.copyWith(
        highestUnlockedLevel: level == current.highestUnlockedLevel
            ? level + 1
            : current.highestUnlockedLevel,
        starsByLevel: Map.unmodifiable(nextStars),
        bestScoreByLevel: Map.unmodifiable(nextScores),
      ),
    );
  }

  Future<void> updateSettings(GameSettings settings) =>
      _replace(state.data.copyWith(settings: settings));

  Future<void> setBooster(String id, int amount) {
    final boosters = {...state.data.boosters, id: amount.clamp(0, 999999)};
    return _replace(state.data.copyWith(boosters: Map.unmodifiable(boosters)));
  }

  Future<void> reset() async {
    await _repository.clear();
    state = const ProgressState(isLoaded: true, data: GameSaveData());
  }

  Future<void> _replace(GameSaveData data) async {
    state = ProgressState(isLoaded: true, data: data);
    await _repository.save(data);
  }
}
