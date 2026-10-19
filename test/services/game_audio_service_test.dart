import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:puff_and_crunch/services/audio/game_audio_service.dart';

void main() {
  test('disabled audio starts no player and can be enabled again', () async {
    final assets = <String>[];
    final audio = GameAudioService(
      soundEnabled: false,
      player: (asset) async => assets.add(asset),
    );

    expect(await audio.play('match'), isFalse);
    expect(assets, isEmpty);

    audio.soundEnabled = true;
    expect(await audio.play('match'), isTrue);
    expect(assets, ['sfx/match.wav']);
  });

  test('a cue still loading cannot create duplicate players', () async {
    final pending = Completer<void>();
    addTearDown(() {
      if (!pending.isCompleted) pending.complete();
    });
    final assets = <String>[];
    final audio = GameAudioService(
      player: (asset) {
        assets.add(asset);
        return pending.future;
      },
    );

    final first = audio.play('match');
    final duplicate = audio.play('match');
    expect(assets, ['sfx/match.wav']);
    expect(await duplicate, isFalse);

    pending.complete();
    expect(await first, isTrue);
    expect(await audio.play('match'), isTrue);
    expect(assets, ['sfx/match.wav', 'sfx/match.wav']);
  });

  test('a burst bounds player startups and releases capacity', () async {
    final pending = Completer<void>();
    addTearDown(() {
      if (!pending.isCompleted) pending.complete();
    });
    var starts = 0;
    final audio = GameAudioService(
      player: (_) {
        starts++;
        return pending.future;
      },
    );
    final requests = [
      'select',
      'swap',
      'match',
      'cascade',
      'fall',
      'land',
      'special_create',
      'blocker_hit',
      'sugar_beam',
      'oven_burst',
    ].map(audio.play).toList();

    expect(starts, 6);
    pending.complete();
    final results = await Future.wait(requests);
    expect(results.where((started) => started), hasLength(6));
    expect(await audio.play('win'), isTrue);
    expect(starts, 7);
  });

  test('sync and async device failures release the cue for retry', () async {
    var attempts = 0;
    final audio = GameAudioService(
      player: (_) {
        attempts++;
        if (attempts == 1) throw StateError('device unavailable');
        if (attempts == 2) return Future.error(StateError('decode failed'));
        return Future.value();
      },
    );

    expect(await audio.play('win'), isFalse);
    expect(await audio.play('win'), isFalse);
    expect(await audio.play('win'), isTrue);
  });

  testWidgets('a stalled device times out and the next cue can play', (
    tester,
  ) async {
    final stalled = Completer<void>();
    var starts = 0;
    final audio = GameAudioService(
      player: (_) => ++starts == 1 ? stalled.future : Future.value(),
    );
    bool? result;
    final first = audio.play('swap').then((value) => result = value);

    await tester.pump(const Duration(seconds: 3));
    expect(result, isFalse);
    await first;
    expect(await audio.play('swap'), isTrue);

    // Device callbacks arriving after the timeout must also stay isolated.
    stalled.completeError(StateError('late device failure'));
    await tester.pump();
  });
}
