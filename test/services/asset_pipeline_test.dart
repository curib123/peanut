import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:puff_and_crunch/services/assets/game_asset_catalog.dart';
import 'package:puff_and_crunch/services/audio/game_audio_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('all declared original assets are packaged and readable', () async {
    final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    final assets = manifest
        .listAssets()
        .where((path) => path.startsWith('assets/'))
        .toList();

    expect(assets, hasLength(52));
    expect(assets.where((path) => path.endsWith('.svg')), hasLength(33));
    expect(assets.where((path) => path.endsWith('.wav')), hasLength(8));
    expect(assets.where((path) => path.endsWith('.png')), hasLength(1));
    expect(assets.where((path) => path.endsWith('.json')), hasLength(10));

    for (final path in assets) {
      final ByteData bytes = await rootBundle.load(path);
      expect(bytes.lengthInBytes, greaterThan(32), reason: path);
    }
  });

  test('missing SVG returns a renderable original fallback', () async {
    final svg = await GameAssetCatalog.loadSvg('assets/svg/missing.svg');
    expect(svg, contains('<svg'));
    expect(svg, contains('</svg>'));
  });

  test('disabled sound is silent and enabled sound uses sfx path', () async {
    final played = <String>[];
    final audio = GameAudioService(
      soundEnabled: false,
      player: (name) async => played.add(name),
    );

    expect(await audio.play('match'), isFalse);
    expect(played, isEmpty);

    audio.soundEnabled = true;
    expect(await audio.play('match'), isTrue);
    expect(played, ['sfx/match.wav']);
  });

  test('audio playback failures never crash gameplay', () async {
    final audio = GameAudioService(
      player: (_) async => throw StateError('missing device'),
    );
    expect(await audio.play('win'), isFalse);
  });
}
