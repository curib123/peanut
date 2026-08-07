import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:puff_and_crunch/services/content/world_presentation_catalog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('world presentation catalog drives scalable level ranges', () async {
    final catalog = await WorldPresentationCatalog.load();

    expect(catalog.worlds, hasLength(6));
    expect(catalog.lastLevel, 120);
    expect(catalog.worldForLevel(1).id, 'sunrise_bakery');
    expect(catalog.worldForLevel(120).id, 'starlight_bake_off');
    expect(() => catalog.worldForLevel(121), throwsFormatException);
  });

  test('every configured background and music file is packaged', () async {
    final catalog = await WorldPresentationCatalog.load();
    final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    final assets = manifest.listAssets().toSet();

    expect(assets, contains(catalog.main.backgroundAsset));
    expect(assets, contains('assets/audio/music/${catalog.main.musicAsset}'));
    for (final world in catalog.worlds) {
      expect(assets, contains(world.backgroundAsset), reason: world.id);
      expect(
        assets,
        contains('assets/audio/music/${world.musicAsset}'),
        reason: world.id,
      );
    }
  });
}
