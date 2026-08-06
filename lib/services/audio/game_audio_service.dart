import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/services.dart';

typedef SoundPlayer = Future<void> Function(String assetName);

class GameAudioService {
  GameAudioService({required this.player, this.soundEnabled = true});

  factory GameAudioService.flame({bool soundEnabled = true}) =>
      GameAudioService(player: FlameAudio.play, soundEnabled: soundEnabled);

  final SoundPlayer player;
  bool soundEnabled;

  Future<bool> play(String name) async {
    if (!soundEnabled) return false;
    try {
      await player('sfx/$name.wav');
      return true;
    } catch (_) {
      return false;
    }
  }
}

typedef HapticPlayer = Future<void> Function();

class GameHapticsService {
  GameHapticsService({
    this.enabled = true,
    HapticPlayer? light,
    HapticPlayer? success,
  }) : _light = light ?? HapticFeedback.selectionClick,
       _success = success ?? HapticFeedback.mediumImpact;

  bool enabled;
  final HapticPlayer _light;
  final HapticPlayer _success;

  Future<void> tap() async {
    if (!enabled) return;
    try {
      await _light();
    } catch (_) {}
  }

  Future<void> celebrate() async {
    if (!enabled) return;
    try {
      await _success();
    } catch (_) {}
  }
}
