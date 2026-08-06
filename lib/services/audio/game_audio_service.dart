import 'package:flame_audio/flame_audio.dart';

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
