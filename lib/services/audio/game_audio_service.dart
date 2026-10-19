import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/services.dart';

typedef SoundPlayer = Future<void> Function(String assetName);

class GameAudioService {
  GameAudioService({required this.player, this.soundEnabled = true});

  factory GameAudioService.flame({bool soundEnabled = true}) =>
      GameAudioService(player: FlameAudio.play, soundEnabled: soundEnabled);

  final SoundPlayer player;
  bool soundEnabled;
  final Set<String> _pendingCues = {};

  // Bound device/decode requests during cascades and browser audio startup.
  // These are startup slots: the player owns sounds after playback begins.
  static const _maxPendingSounds = 6;
  static const _startupTimeout = Duration(seconds: 2);

  Future<bool> play(String name) async {
    if (!soundEnabled ||
        _pendingCues.length >= _maxPendingSounds ||
        !_pendingCues.add(name)) {
      return false;
    }
    try {
      await player('sfx/$name.wav').timeout(_startupTimeout);
      return true;
    } catch (_) {
      return false;
    } finally {
      _pendingCues.remove(name);
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
