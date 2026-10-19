import 'dart:convert';

import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:puff_and_crunch/app/app.dart';
import 'package:puff_and_crunch/app/router.dart';
import 'package:puff_and_crunch/features/progress/data/save_repository.dart';
import 'package:puff_and_crunch/features/progress/domain/game_save_data.dart';
import 'package:puff_and_crunch/game/domain/match3.dart';
import 'package:puff_and_crunch/game/presentation/island_match_game.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets(
    'a played win saves its unlock and continues to the next recipe',
    (tester) async {
      SharedPreferences.setMockInitialValues({
        SharedPreferencesSaveRepository.saveKey: jsonEncode(
          const GameSaveData(
            settings: GameSettings(
              soundEnabled: false,
              musicEnabled: false,
              hapticsEnabled: false,
              reducedMotion: true,
            ),
          ).toJson(),
        ),
      });
      appRouter.go('/');
      await tester.pumpWidget(const ProviderScope(child: PuffAndCrunchApp()));
      await tester.pumpAndSettle();
      appRouter.go('/game/1');
      await tester.pump();
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(seconds: 2)),
      );
      final boardFinder = find.byWidgetPredicate(
        (widget) => widget is GameWidget,
      );
      IslandMatchGame? loaded;
      for (var frame = 0; frame < 180; frame++) {
        await tester.pump(const Duration(milliseconds: 16));
        if (boardFinder.evaluate().isNotEmpty) {
          final candidate =
              tester.widget<GameWidget>(boardFinder).game as IslandMatchGame;
          await tester.runAsync(() async => candidate.toBeLoaded());
          await tester.pump();
          await tester.runAsync(candidate.ready);
          await tester.pump();
          if (candidate.isActive && !candidate.isInputLocked) {
            loaded = candidate;
            break;
          }
        }
      }
      expect(loaded, isNotNull);
      final game = loaded!;
      const validator = MoveValidator();
      for (
        var move = 0;
        move < 27 && game.hud.value.status == LevelStatus.playing;
        move++
      ) {
        (Position, Position)? legal;
        for (final first in game.board.positions) {
          for (final second in [
            Position(first.row, first.column + 1),
            Position(first.row + 1, first.column),
          ]) {
            if (validator.isValidSwap(game.board, first, second)) {
              legal = (first, second);
              break;
            }
          }
          if (legal != null) break;
        }
        expect(legal, isNotNull);
        var finished = false;
        final turn = game.attemptSwap(legal!.$1, legal.$2).then((result) {
          finished = true;
          return result;
        });
        for (var frame = 0; frame < 600 && !finished; frame++) {
          await tester.pump(const Duration(milliseconds: 16));
        }
        expect(finished, isTrue, reason: 'Turn $move must settle.');
        expect(await turn, isTrue);
      }
      expect(game.hud.value.status, LevelStatus.won);
      await tester.pump(const Duration(seconds: 2));
      expect(find.text('Perfect Batch!'), findsOneWidget);
      final saved = await SharedPreferencesSaveRepository().load();
      expect(saved.highestUnlockedLevel, 2);
      expect(saved.bestScoreFor(1), game.hud.value.score);
      expect(
        saved.starsFor(1),
        game.level!.starsForCompletedScore(game.hud.value.score),
      );

      await tester.ensureVisible(find.text('Next Recipe'));
      await tester.tap(find.text('Next Recipe'));
      await tester.pumpAndSettle();
      expect(appRouter.routeInformationProvider.value.uri.path, '/level/2');
      expect(find.text('Start Level'), findsOneWidget);
      expect(find.text('This recipe is still locked'), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 2));
    },
  );
}
