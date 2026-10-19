import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:puff_and_crunch/core/widgets/game_primary_button.dart';
import 'package:puff_and_crunch/services/audio/game_audio_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('primary buttons respect the saved sound setting', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'puff_and_crunch_save': '{"settings":{"sound":false}}',
    });
    final played = <String>[];
    var taps = 0;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          gameButtonAudioProvider.overrideWithValue(
            GameAudioService(player: (name) async => played.add(name)),
          ),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: GamePrimaryButton(label: 'Start', onPressed: () => taps++),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Start'));
    await tester.pumpAndSettle();
    expect(taps, 1);
    expect(played, isEmpty);
  });

  testWidgets('primary buttons can be activated with a keyboard', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    var taps = 0;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          gameButtonAudioProvider.overrideWithValue(
            GameAudioService(player: (_) async {}),
          ),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: GamePrimaryButton(label: 'Start', onPressed: () => taps++),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(taps, 1);
  });
}
