import 'dart:ui';

import 'package:flame/game.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:puff_and_crunch/game/domain/match3.dart';
import 'package:puff_and_crunch/game/presentation/hint_component.dart';

import 'board_animation_test.dart' as fixture;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Board board() => fixture.createGame().board.copy();

  test('hint waits six idle seconds and chooses the first legal swap', () {
    final tray = board();
    final before = tray.toRows();
    final hints = IdleHintController();
    expect(hints.update(5.9, board: tray), isNull);
    final move = hints.update(.11, board: tray);
    expect(move, (first: const Position(0, 1), second: const Position(1, 1)));
    expect(tray.toRows(), before);
  });

  test('interrupted input restarts the entire idle delay', () {
    final hints = IdleHintController();
    final tray = board();
    expect(hints.update(6.1, board: tray), isNotNull);
    expect(hints.update(.1, board: tray, enabled: false), isNull);
    expect(hints.update(5.9, board: tray), isNull);
    expect(hints.update(.2, board: tray), isNotNull);
    hints.reset();
    expect(hints.update(.1, board: tray), isNull);
  });

  test('locked specials and inaccessible cells are never suggested', () {
    final tray = BoardGenerator(seed: 0).generate(rows: 3, columns: 3)
      ..setPiece(
        const Position(1, 0),
        const Piece(PieceKind.egg, specialKind: SpecialKind.ovenBurst),
      );
    expect(IdleHintController().update(7, board: tray), isNotNull);
    expect(
      IdleHintController().update(
        7,
        board: tray,
        unavailableCells: {const Position(1, 0)},
      ),
      isNull,
    );
    final holes = board();
    holes.setPiece(const Position(0, 1), null);
    final unavailable = holes.positions.toSet();
    expect(
      IdleHintController().update(
        7,
        board: holes,
        unavailableCells: unavailable,
      ),
      isNull,
    );
  });

  test('reduced-motion hints retain a static canvas signature', () async {
    final hint = HintComponent(
      move: (first: const Position(0, 1), second: const Position(1, 1)),
      cellExtent: 48,
      size: Vector2(144, 192),
      reducedMotion: true,
    );
    final first = await pixels(hint);
    hint.update(3);
    expect(await pixels(hint), first);
  });

  testWidgets('board cancels its hint as soon as an animation starts', (
    tester,
  ) async {
    final game = fixture.createGame();
    await fixture.mountGame(tester, game);
    game.update(6.1);
    await tester.pump();
    expect(
      game.boardComponent.children.whereType<HintComponent>(),
      hasLength(1),
    );
    final turn = game.attemptSwap(const Position(0, 0), const Position(0, 1));
    await tester.pump();
    expect(game.boardComponent.children.whereType<HintComponent>(), isEmpty);
    var completed = false;
    turn.then((_) => completed = true);
    for (var i = 0; i < 100 && !completed; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    expect(completed, isTrue);
    expect(tester.takeException(), isNull);
  });
}

Future<List<int>> pixels(HintComponent hint) async {
  final recorder = PictureRecorder();
  hint.render(Canvas(recorder));
  final picture = recorder.endRecording();
  final image = await picture.toImage(144, 192);
  final bytes = (await image.toByteData())!.buffer.asUint8List().toList();
  image.dispose();
  picture.dispose();
  return bytes;
}
