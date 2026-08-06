import 'dart:ui';

import 'package:flame/game.dart';

import '../domain/match3.dart';
import 'board_component.dart';
import 'turn_input_gate.dart';

class IslandMatchGame extends FlameGame {
  IslandMatchGame({
    Board? initialBoard,
    int seed = 20260806,
    this.animationDuration = 0.18,
  }) : _seed = seed,
       board = initialBoard ?? BoardGenerator(seed: seed).generate();

  final int _seed;
  final double animationDuration;
  final Board board;
  late final TurnEngine _turnEngine;
  late final BoardComponent boardComponent;
  final TurnInputGate _inputGate = TurnInputGate();

  bool get isInputLocked => _inputGate.isLocked;

  @override
  Color backgroundColor() => const Color(0xFFFFF4D6);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _turnEngine = TurnEngine(
      resolver: BoardResolver(seed: _seed + 1),
      shuffler: BoardShuffler(seed: _seed + 2),
    );
    boardComponent = BoardComponent(board: board);
    add(boardComponent);
    _layout(size);
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    if (isLoaded && boardComponent.isMounted) _layout(size);
  }

  Future<bool> attemptSwap(Position first, Position second) async {
    final result = await _inputGate.run(() async {
      final resolution = _turnEngine.resolveSwap(board, first, second);
      if (!resolution.isValid) {
        await boardComponent.animateInvalidSwap(
          first,
          second,
          animationDuration * 0.75,
        );
        return false;
      }
      await boardComponent.animateResolution(
        first,
        second,
        resolution,
        animationDuration,
      );
      return true;
    });
    return result ?? false;
  }

  void _layout(Vector2 canvasSize) {
    final availableWidth = canvasSize.x - 24;
    final availableHeight = canvasSize.y - 24;
    final extent = availableWidth < availableHeight
        ? availableWidth
        : availableHeight;
    boardComponent
      ..position = Vector2(
        (canvasSize.x - extent) / 2,
        (canvasSize.y - extent) / 2,
      )
      ..resizeBoard(Vector2.all(extent));
  }
}
