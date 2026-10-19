import 'dart:ui';

import 'package:flame/game.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:puff_and_crunch/game/domain/piece.dart';
import 'package:puff_and_crunch/game/presentation/power_effect_component.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  PowerEffectComponent effect(SpecialKind kind, {bool reduced = false}) =>
      PowerEffectComponent(
        kind: kind,
        origin: const Offset(160, 200),
        size: Vector2(320, 400),
        cellExtent: 48,
        targets: List.generate(
          80,
          (i) => Offset((i * 39) % 320, (i * 61) % 400),
        ),
        reducedMotion: reduced,
      );

  test('power flights retain a bounded immutable target snapshot', () {
    final power = effect(SpecialKind.goldenRecipeSpark);
    expect(power.targets, hasLength(16));
    expect(() => power.targets.clear(), throwsUnsupportedError);
  });

  test('each power has a distinct readable canvas signature', () async {
    final signatures = <int>{};
    for (final kind in SpecialKind.values) {
      final power = effect(kind)..update(.24);
      final bytes = await pixels(power);
      var signature = 0;
      for (final byte in bytes) {
        signature = (signature * 31 + byte) & 0x7fffffff;
      }
      signatures.add(signature);
    }
    expect(signatures, hasLength(5));
  });

  test(
    'reduced-motion power cues retain a static visual until expiry',
    () async {
      for (final kind in SpecialKind.values) {
        final power = effect(kind, reduced: true);
        final first = await pixels(power);
        power.update(.08);
        expect(await pixels(power), first, reason: kind.name);
      }
    },
  );

  test('power visuals stay inside the board canvas', () async {
    for (final kind in SpecialKind.values) {
      final power = effect(kind)..update(.25);
      final bytes = await pixels(power);
      var outsidePixels = 0;
      for (var y = 0; y < 440; y++) {
        for (var x = 0; x < 360; x++) {
          if (x >= 20 && x < 340 && y >= 20 && y < 420) continue;
          if (bytes[(y * 360 + x) * 4 + 3] != 0) outsidePixels++;
        }
      }
      expect(outsidePixels, 0, reason: kind.name);
    }
  });

  testWidgets('all power cues and crumbs retire after their finite lifetime', (
    tester,
  ) async {
    final game = FlameGame(
      children: [
        for (final kind in SpecialKind.values) effect(kind),
        for (final kind in SpecialKind.values) effect(kind, reduced: true),
        MatchSparklesComponent(
          origins: List.filled(1000, const Offset(100, 100)),
          extent: 48,
          boardSize: Vector2(320, 400),
        ),
      ],
    );
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: GameWidget(game: game),
      ),
    );
    await tester.runAsync(() async => await game.toBeLoaded());
    await tester.pump();
    await tester.runAsync(game.ready);
    expect(
      game.children.whereType<MatchSparklesComponent>().single.origins,
      hasLength(24),
    );
    game.update(2);
    await tester.pump();
    expect(game.children.whereType<PowerEffectComponent>(), isEmpty);
    expect(game.children.whereType<MatchSparklesComponent>(), isEmpty);
    expect(tester.takeException(), isNull);
  });
}

Future<List<int>> pixels(PowerEffectComponent power) async {
  final recorder = PictureRecorder();
  final canvas = Canvas(recorder)..translate(20, 20);
  power.render(canvas);
  final picture = recorder.endRecording();
  final image = await picture.toImage(360, 440);
  final bytes = (await image.toByteData())!.buffer.asUint8List().toList();
  image.dispose();
  picture.dispose();
  return bytes;
}
