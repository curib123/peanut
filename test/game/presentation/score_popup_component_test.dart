import 'package:flame/game.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:puff_and_crunch/game/domain/match3.dart';
import 'package:puff_and_crunch/game/presentation/score_popup_component.dart';

void main() {
  test('cascade rewards equal the domain turn score without changing it', () {
    final session = LevelSession(
      board: BoardGenerator(seed: 17).generate()
        ..setPiece(
          const Position(3, 2),
          const Piece(PieceKind.peanut, specialKind: SpecialKind.ovenBurst),
        ),
      moveLimit: 10,
      goals: GoalTracker([
        GoalState(kind: GoalKind.targetScore, target: 999999),
      ]),
      turnEngine: TurnEngine(
        resolver: BoardResolver(seed: 18),
        shuffler: BoardShuffler(seed: 19),
      ),
    );
    final turn = session.play(const Position(3, 2), const Position(3, 3));
    expect(turn.resolution.isValid, isTrue);
    final authoritativeScore = session.score;
    var displayed = 0;
    for (var i = 0; i < turn.resolution.cascades.length; i++) {
      final popup = ScorePopupComponent.forCascade(
        cascade: turn.resolution.cascades[i],
        cascadeIndex: i,
        origin: Vector2(200, 200),
        cellExtent: 48,
        reducedMotion: false,
      );
      displayed += popup.score;
    }
    expect(displayed, turn.progress.score);
    expect(session.score, authoritativeScore);
  });

  test('later cascades include their multiplier and special bonuses', () {
    final board = Board.filled(3, 3, const Piece(PieceKind.peanut));
    final popup = ScorePopupComponent.forCascade(
      cascade: CascadeFrame(
        matched: {
          const Position(0, 0),
          const Position(0, 1),
          const Position(0, 2),
        },
        activatedSpecials: {const Position(0, 0), const Position(0, 1)},
        beforeClear: board,
        afterRemoval: board,
        afterGravity: board,
        afterRefill: board,
      ),
      cascadeIndex: 2,
      origin: Vector2.zero(),
      cellExtent: 48,
      reducedMotion: true,
    );
    expect(popup.score, 1040);
    expect(popup.cascadeMultiplier, 3);
  });

  testWidgets('rewards expire and reduced motion keeps their origin fixed', (
    tester,
  ) async {
    final popup = ScorePopupComponent(
      score: 180,
      cascadeMultiplier: 1,
      origin: Vector2(150, 150),
      cellExtent: 48,
      reducedMotion: true,
    );
    final game = FlameGame(children: [popup]);
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: GameWidget(game: game),
      ),
    );
    await tester.runAsync(() async => await game.toBeLoaded());
    await tester.pump();
    await tester.runAsync(game.ready);
    final origin = popup.position.clone();
    game.update(.3);
    expect(popup.position, origin);
    expect(popup.scale, Vector2.all(1));
    game.update(2);
    await tester.pump();
    expect(game.children.whereType<ScorePopupComponent>(), isEmpty);
    expect(tester.takeException(), isNull);
  });
}
