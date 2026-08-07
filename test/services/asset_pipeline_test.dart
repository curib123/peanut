import 'dart:ui' as ui;

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

    expect(assets, hasLength(212));
    expect(assets.where((path) => path.endsWith('.svg')), hasLength(33));
    expect(assets.where((path) => path.endsWith('.wav')), hasLength(26));
    expect(assets.where((path) => path.endsWith('.png')), hasLength(26));
    expect(assets.where((path) => path.endsWith('.webp')), hasLength(6));
    expect(assets.where((path) => path.endsWith('.json')), hasLength(121));

    for (final path in assets) {
      final ByteData bytes = await rootBundle.load(path);
      expect(bytes.lengthInBytes, greaterThan(32), reason: path);
    }
  });

  test(
    'phase 11 production art covers every gameplay piece and world',
    () async {
      final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
      final assets = manifest.listAssets().toSet();
      for (final id in [
        'peanut',
        'egg',
        'sugar_crystal',
        'caramel_ribbon',
        'coconut_cream',
        'cocoa_crumb',
      ]) {
        expect(assets, contains('assets/images/pieces/$id.png'));
      }
      for (final id in [
        'sunrise_bakery',
        'peanut_grove',
        'egg_cloud_kitchen',
        'sugar_harbor',
        'festival_oven',
        'starlight_bake_off',
      ]) {
        expect(assets, contains('assets/images/worlds/$id.webp'));
      }
      expect(assets, contains('assets/images/worlds/level_road_segment.png'));
      for (final asset in [
        'primary_button.png',
        'round_button.png',
        'bakery_panel.png',
        'puff_crunch_logo.png',
      ]) {
        expect(assets, contains('assets/images/ui/$asset'));
      }
      expect(assets, contains('assets/images/effects/match_burst_sheet.png'));
      expect(assets, contains('assets/images/specials/peanut_kisses.png'));
    },
  );

  test('match burst sheet keeps the expected eight-frame grid', () async {
    final bytes = await rootBundle.load(
      'assets/images/effects/match_burst_sheet.png',
    );
    final codec = await ui.instantiateImageCodec(bytes.buffer.asUint8List());
    final frame = await codec.getNextFrame();
    expect(frame.image.width, 1536);
    expect(frame.image.height, 1024);
    expect(frame.image.width ~/ 4, 384);
    expect(frame.image.height ~/ 2, 512);
    codec.dispose();
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

  test('animation and every special power have packaged sound cues', () async {
    final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    final assets = manifest.listAssets().toSet();
    for (final cue in [
      'select',
      'swap',
      'invalid',
      'match',
      'cascade',
      'fall',
      'land',
      'shuffle',
      'blocker_hit',
      'special_create',
      'sugar_beam',
      'golden_spark',
      'oven_burst',
      'peanut_spinner',
      'peanut_kisses',
      'win',
      'lose',
    ]) {
      expect(assets, contains('assets/audio/sfx/$cue.wav'), reason: cue);
    }
  });

  test('audio playback failures never crash gameplay', () async {
    final audio = GameAudioService(
      player: (_) async => throw StateError('missing device'),
    );
    expect(await audio.play('win'), isFalse);
  });

  test('haptics respect settings and swallow device failures', () async {
    var taps = 0;
    final haptics = GameHapticsService(
      enabled: false,
      light: () async => taps++,
    );
    await haptics.tap();
    expect(taps, 0);
    haptics.enabled = true;
    await haptics.tap();
    expect(taps, 1);
    final failing = GameHapticsService(
      light: () async => throw StateError('device'),
    );
    await expectLater(failing.tap(), completes);
  });
}
