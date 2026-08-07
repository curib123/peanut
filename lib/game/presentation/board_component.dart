import 'dart:async';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/events.dart';
import 'package:flutter/animation.dart';

import '../domain/match3.dart' as domain;
import 'island_match_game.dart';
import 'piece_component.dart';

class BoardComponent extends PositionComponent
    with TapCallbacks, DragCallbacks, HasGameReference<IslandMatchGame> {
  BoardComponent({required domain.Board board, required this.blockers})
    : _board = board.copy();

  domain.Board _board;
  final domain.BlockerGrid blockers;
  final Map<domain.Position, PieceComponent> _pieces = {};
  final List<SpriteComponent> _blockerSprites = [];
  domain.Position? _selected;
  domain.Position? _dragStart;
  Vector2 _dragDelta = Vector2.zero();

  double get cellExtent => size.x / _board.columns;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _rebuild(_board);
    await refreshBlockers();
  }

  @override
  void render(Canvas canvas) {
    final cell = cellExtent;
    final tray = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.x, size.y),
      const Radius.circular(24),
    );
    canvas.drawRRect(tray, Paint()..color = const Color(0xD66B321B));
    canvas.drawRRect(
      tray,
      Paint()
        ..color = const Color(0xFFFFC85A)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5,
    );
    for (var row = 0; row < _board.rows; row++) {
      for (var column = 0; column < _board.columns; column++) {
        final rect = RRect.fromRectAndRadius(
          Rect.fromLTWH(column * cell + 3, row * cell + 3, cell - 6, cell - 6),
          Radius.circular(cell * .22),
        );
        canvas.drawRRect(rect, Paint()..color = const Color(0xB8FFF2D0));
        canvas.drawRRect(
          rect,
          Paint()
            ..color = const Color(0x44FFFFFF)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5,
        );
      }
    }
  }

  @override
  void onTapUp(TapUpEvent event) {
    if (game.isInputLocked) return;
    final tapped = _positionAt(event.localPosition);
    if (tapped == null) return;
    final selected = _selected;
    if (selected == null || !selected.isOrthogonallyAdjacentTo(tapped)) {
      _select(tapped == selected ? null : tapped);
      return;
    }
    _select(null);
    unawaited(game.attemptSwap(selected, tapped));
  }

  @override
  void onDragStart(DragStartEvent event) {
    super.onDragStart(event);
    if (game.isInputLocked) return;
    _dragStart = _positionAt(event.localPosition);
    _dragDelta = Vector2.zero();
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    if (_dragStart != null) _dragDelta.add(event.localDelta);
  }

  @override
  void onDragEnd(DragEndEvent event) {
    super.onDragEnd(event);
    final start = _dragStart;
    _dragStart = null;
    if (start == null ||
        game.isInputLocked ||
        _dragDelta.length < cellExtent * 0.25) {
      return;
    }
    final horizontal = _dragDelta.x.abs() > _dragDelta.y.abs();
    final target = domain.Position(
      start.row + (horizontal ? 0 : (_dragDelta.y > 0 ? 1 : -1)),
      start.column + (horizontal ? (_dragDelta.x > 0 ? 1 : -1) : 0),
    );
    if (_board.contains(target)) {
      _select(null);
      unawaited(game.attemptSwap(start, target));
    }
  }

  Future<void> animateInvalidSwap(
    domain.Position first,
    domain.Position second,
    double duration,
  ) async {
    await _animateSwap(first, second, duration);
    await _animateSwap(first, second, duration, returnToOrigin: true);
    if (!game.reducedMotion) {
      final shake = MoveEffect.by(
        Vector2(7, 0),
        EffectController(duration: .045, reverseDuration: .045, repeatCount: 2),
      );
      add(shake);
      await shake.completed;
    }
  }

  Future<void> animateResolution(
    domain.Position first,
    domain.Position second,
    domain.TurnResolution resolution,
    double duration,
  ) async {
    await _animateSwap(first, second, duration);
    _board = resolution.afterSwap.copy();
    _swapPieceKeys(first, second);

    for (
      var cascadeIndex = 0;
      cascadeIndex < resolution.cascades.length;
      cascadeIndex++
    ) {
      final cascade = resolution.cascades[cascadeIndex];
      await game.audio.play(
        cascade.activatedSpecials.isNotEmpty
            ? 'special'
            : cascadeIndex == 0
            ? 'match'
            : 'cascade',
      );
      final effects = <Future<void>>[];
      for (final position in cascade.matched) {
        final piece = _pieces[position];
        if (piece == null) continue;
        final effect = ScaleEffect.to(
          Vector2.zero(),
          EffectController(duration: duration * 0.75),
        );
        piece.add(effect);
        effects.add(effect.completed);
        if (!game.reducedMotion) _burstAt(position);
      }
      await Future.wait(effects);
      _rebuild(cascade.afterRemoval);
      await _rebuildFalling(cascade.afterGravity, duration);
      await _rebuildFalling(cascade.afterRefill, duration);
    }
    _rebuild(resolution.finalBoard);
    await refreshBlockers();
  }

  Future<void> refreshBlockers() async {
    for (final component in _blockerSprites) {
      component.removeFromParent();
    }
    _blockerSprites.clear();
    for (final entry in blockers.states.entries) {
      try {
        final id = switch (entry.value.kind) {
          domain.BlockerKind.sugarFrosting => 'sugar_frosting',
          domain.BlockerKind.peanutCrate => 'peanut_crate',
          domain.BlockerKind.stickyCaramel => 'sticky_caramel',
          domain.BlockerKind.chocolateCrumbs => 'chocolate_crumbs',
          domain.BlockerKind.ovenStone => 'oven_stone',
          domain.BlockerKind.bakersTwine => 'bakers_twine',
        };
        final component = SpriteComponent(
          sprite: await Sprite.load('blockers/$id.png'),
          position: _cellPosition(entry.key),
          size: Vector2.all(cellExtent),
          priority: 10,
        );
        _blockerSprites.add(component);
        add(component);
      } catch (_) {
        // The board remains playable if a presentation-only asset is missing.
      }
    }
  }

  void _burstAt(domain.Position position) {
    const colors = [Color(0xFFFFC43D), Color(0xFFE968A8), Color(0xFF72D5E8)];
    for (var index = 0; index < 5; index++) {
      final particle = CircleComponent(
        radius: cellExtent * .055,
        paint: Paint()..color = colors[index % colors.length],
        position: _cellPosition(position) + Vector2.all(cellExtent / 2),
        anchor: Anchor.center,
      );
      add(particle);
      particle.add(
        MoveEffect.by(
          Vector2(
            (index - 2) * cellExtent * .18,
            (index.isEven ? -1 : 1) * cellExtent * .25,
          ),
          EffectController(duration: .28),
        )..onComplete = particle.removeFromParent,
      );
      particle.add(OpacityEffect.fadeOut(EffectController(duration: .28)));
    }
  }

  void resizeBoard(Vector2 newSize) {
    size = newSize;
    _rebuild(_board);
    unawaited(refreshBlockers());
  }

  Future<void> _animateSwap(
    domain.Position first,
    domain.Position second,
    double duration, {
    bool returnToOrigin = false,
  }) async {
    final firstPiece = _pieces[first];
    final secondPiece = _pieces[second];
    if (firstPiece == null || secondPiece == null) return;
    final firstEffect = MoveEffect.to(
      _cellPosition(returnToOrigin ? first : second),
      EffectController(duration: duration, curve: Curves.easeInOut),
    );
    final secondEffect = MoveEffect.to(
      _cellPosition(returnToOrigin ? second : first),
      EffectController(duration: duration, curve: Curves.easeInOut),
    );
    firstPiece.add(firstEffect);
    secondPiece.add(secondEffect);
    await Future.wait([firstEffect.completed, secondEffect.completed]);
  }

  void _swapPieceKeys(domain.Position first, domain.Position second) {
    final firstPiece = _pieces.remove(first);
    final secondPiece = _pieces.remove(second);
    if (firstPiece != null) _pieces[second] = firstPiece;
    if (secondPiece != null) _pieces[first] = secondPiece;
  }

  void _rebuild(domain.Board board) {
    _replacePieces(board, animateFall: false, duration: 0);
  }

  Future<void> _rebuildFalling(domain.Board board, double duration) async {
    final effects = _replacePieces(
      board,
      animateFall: true,
      duration: duration,
    );
    await Future.wait(effects);
  }

  List<Future<void>> _replacePieces(
    domain.Board board, {
    required bool animateFall,
    required double duration,
  }) {
    final effects = <Future<void>>[];
    for (final piece in _pieces.values) {
      piece.removeFromParent();
    }
    _pieces.clear();
    _board = board.copy();
    final extent = cellExtent;
    for (final position in board.positions) {
      final piece = board.pieceAt(position);
      if (piece == null) continue;
      final destination = _cellPosition(position);
      final component = PieceComponent(
        piece: piece,
        position: animateFall
            ? destination - Vector2(0, extent * 0.65)
            : destination,
        extent: extent,
      );
      _pieces[position] = component;
      add(component);
      if (animateFall) {
        final effect = MoveEffect.to(
          destination,
          EffectController(duration: duration, curve: Curves.easeOutCubic),
        );
        component.add(effect);
        if (!game.reducedMotion) {
          component.add(
            ScaleEffect.to(
              Vector2(1.06, .94),
              EffectController(duration: duration + .07, reverseDuration: .08),
            ),
          );
        }
        effects.add(effect.completed);
      }
    }
    return effects;
  }

  Vector2 _cellPosition(domain.Position position) =>
      Vector2(position.column * cellExtent, position.row * cellExtent);

  domain.Position? _positionAt(Vector2 local) {
    final column = (local.x / cellExtent).floor();
    final row = (local.y / cellExtent).floor();
    final position = domain.Position(row, column);
    return _board.contains(position) ? position : null;
  }

  void _select(domain.Position? position) {
    if (_selected != null) _pieces[_selected]?.isSelected = false;
    _selected = position;
    if (position != null) _pieces[position]?.isSelected = true;
  }
}
