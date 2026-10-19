import 'dart:async';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/events.dart';
import 'package:flutter/animation.dart';
import 'package:flutter/material.dart' as ui;

import '../domain/match3.dart' as domain;
import 'island_match_game.dart';
import 'match_burst_component.dart';
import 'piece_component.dart';
import 'polished_sprite_component.dart';
import 'power_effect_component.dart';
import 'score_popup_component.dart';

class BoardComponent extends PositionComponent
    with TapCallbacks, DragCallbacks, HasGameReference<IslandMatchGame> {
  BoardComponent({required domain.Board board, required this.blockers})
    : _board = board.copy();

  domain.Board _board;
  final domain.BlockerGrid blockers;
  final Map<domain.Position, PieceComponent> _pieces = {};
  final List<PolishedSpriteComponent> _blockerSprites = [];
  final List<ScorePopupComponent> _scorePopups = [];
  bool _animating = false;
  Vector2? _pendingSize;
  int _blockerRequest = 0;
  domain.Position? _selected;
  domain.Position? _dragStart;
  Vector2 _dragDelta = Vector2.zero();

  double get cellExtent => size.x / _board.columns;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _rebuild(_board);
    await refreshBlockers();
    add(_BoardMarkers(this));
  }

  @override
  void render(Canvas canvas) {
    final cell = cellExtent;
    final tray = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.x, size.y),
      const Radius.circular(24),
    );
    canvas.drawShadow(Path()..addRRect(tray), const Color(0xCC100A06), 8, true);
    canvas.drawRRect(
      tray,
      Paint()
        ..shader = const ui.LinearGradient(
          begin: ui.Alignment.topLeft,
          end: ui.Alignment.bottomRight,
          colors: [Color(0xFFBA8753), Color(0xFF4D281B), Color(0xFFBA8753)],
          stops: [0, .55, 1],
        ).createShader(tray.outerRect),
    );
    canvas.drawRRect(
      tray,
      Paint()
        ..color = const Color(0xFFFFDFA1)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.3,
    );
    final objectives = game.boardObjectives;
    for (var row = 0; row < _board.rows; row++) {
      for (var column = 0; column < _board.columns; column++) {
        final position = domain.Position(row, column);
        if (game.level != null &&
            !game.level!.playableCells.contains(position)) {
          continue;
        }
        final rect = RRect.fromRectAndRadius(
          Rect.fromLTWH(column * cell + 2, row * cell + 2, cell - 4, cell - 4),
          Radius.circular(cell * .2),
        );
        canvas.drawRRect(
          rect,
          Paint()
            ..color = (row + column).isEven
                ? const Color(0xF02F4547)
                : const Color(0xF0395152),
        );
        canvas.drawRRect(
          rect,
          Paint()
            ..color = const Color(0x26FFF1BD)
            ..style = PaintingStyle.stroke
            ..strokeWidth = .7,
        );
        if (objectives.cream.contains(position)) {
          canvas.drawRRect(rect, Paint()..color = const Color(0x6687DFD8));
        }
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
    _animating = true;
    try {
      await _animateSwap(first, second, duration);
      if (!game.isActive) return;
      await _animateSwap(first, second, duration, returnToOrigin: true);
      if (!game.reducedMotion) {
        final shake = MoveEffect.by(
          Vector2(7, 0),
          EffectController(
            duration: .045,
            reverseDuration: .045,
            repeatCount: 2,
          ),
        );
        add(shake);
        await shake.completed;
      }
    } finally {
      _finishAnimation();
    }
  }

  Future<void> animateResolution(
    domain.Position first,
    domain.Position second,
    domain.TurnResolution resolution,
    double duration,
  ) async {
    _animating = true;
    try {
      await _animateSwap(first, second, duration);
      if (!game.isActive) return;
      _board = resolution.afterSwap.copy();
      _swapPieceKeys(first, second);

      for (
        var cascadeIndex = 0;
        cascadeIndex < resolution.cascades.length;
        cascadeIndex++
      ) {
        final cascade = resolution.cascades[cascadeIndex];
        _showCascadeReward(cascade, cascadeIndex);
        final activatedKinds = cascade.activatedSpecials
            .map(
              (position) => cascade.beforeClear.pieceAt(position)?.specialKind,
            )
            .whereType<domain.SpecialKind>()
            .toSet();
        if (activatedKinds.isNotEmpty) {
          for (final kind in activatedKinds.take(2)) {
            unawaited(game.audio.play(_specialSound(kind)));
          }
        } else {
          unawaited(game.audio.play(cascadeIndex == 0 ? 'match' : 'cascade'));
        }
        final createdSpecial = cascade.matched.any((position) {
          final before = cascade.beforeClear.pieceAt(position);
          final after = cascade.afterRemoval.pieceAt(position);
          return after?.isSpecial == true &&
              before?.specialKind != after?.specialKind;
        });
        if (createdSpecial) unawaited(game.audio.play('special_create'));
        if (_hitsBlocker(cascade.matched)) {
          unawaited(game.audio.play('blocker_hit'));
        }
        for (final position in cascade.activatedSpecials.take(4)) {
          final special = cascade.beforeClear.pieceAt(position);
          if (special?.specialKind == null) continue;
          add(
            PowerEffectComponent(
              kind: special!.specialKind!,
              origin: _center(position),
              size: size.clone(),
              cellExtent: cellExtent,
              vertical:
                  special.beamOrientation == domain.BeamOrientation.vertical,
              targets: cascade.matched.take(16).map(_center).toList(),
              reducedMotion: game.reducedMotion,
            ),
          );
        }
        if (!game.reducedMotion) {
          add(
            MatchSparklesComponent(
              origins: cascade.matched.map(_center),
              extent: cellExtent,
            ),
          );
        }
        var burstCount = 0;
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
          if (burstCount++ < 12) _burstAt(position);
        }
        await Future.wait(effects);
        if (!game.isActive) return;
        _rebuild(cascade.afterRemoval);
        await _rebuildFalling(cascade.afterGravity, duration);
        if (!game.isActive) return;
        await _rebuildFalling(cascade.afterRefill, duration);
        if (!game.isActive) return;
      }
      if (resolution.wasShuffled) {
        unawaited(game.audio.play('shuffle'));
        await _animateReshuffle(resolution.finalBoard, duration);
      } else {
        _rebuild(resolution.finalBoard);
      }
      await refreshBlockers();
    } finally {
      _finishAnimation();
    }
  }

  void _finishAnimation() {
    _animating = false;
    final pending = _pendingSize;
    _pendingSize = null;
    if (pending != null && game.isActive) resizeBoard(pending);
  }

  Future<void> refreshBlockers() async {
    final request = ++_blockerRequest;
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
        final component = PolishedSpriteComponent(
          sprite: await Sprite.load('blockers/$id.png'),
          position: _cellPosition(entry.key),
          size: Vector2.all(cellExtent),
          priority: 10,
          reducedMotion: game.reducedMotion,
          idleStrength: .45,
        );
        if (!game.isActive || request != _blockerRequest) return;
        _blockerSprites.add(component);
        add(component);
      } catch (_) {
        // The board remains playable if a presentation-only asset is missing.
      }
    }
  }

  void _burstAt(domain.Position position) {
    add(
      MatchBurstComponent(
        position: _cellPosition(position) + Vector2.all(cellExtent / 2),
        size: Vector2(cellExtent * 1.7, cellExtent * 1.35),
        reducedMotion: game.reducedMotion,
      ),
    );
  }

  void _showCascadeReward(domain.CascadeFrame cascade, int cascadeIndex) {
    if (cascade.matched.isEmpty) return;
    _scorePopups.removeWhere((popup) => popup.isRemoving || popup.isRemoved);
    // Rapid cascades can overlap briefly, but never accumulate text layers.
    while (_scorePopups.length >= 3) {
      _scorePopups.removeAt(0).removeFromParent();
    }
    var center = Offset.zero;
    for (final cell in cascade.matched) {
      center += _center(cell);
    }
    center = center / cascade.matched.length.toDouble();
    final extent = cellExtent;
    final horizontalMargin = (extent * 1.3).clamp(0.0, size.x / 2);
    final topMargin = (extent * 1.25).clamp(0.0, size.y / 2);
    final popup = ScorePopupComponent.forCascade(
      cascade: cascade,
      cascadeIndex: cascadeIndex,
      origin: Vector2(
        center.dx.clamp(horizontalMargin, size.x - horizontalMargin),
        center.dy.clamp(topMargin, size.y - extent * .5),
      ),
      cellExtent: extent,
      reducedMotion: game.reducedMotion,
    );
    _scorePopups.add(popup);
    add(popup);
  }

  void resizeBoard(Vector2 newSize) {
    if (_animating) {
      _pendingSize = newSize.clone();
      return;
    }
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
    if (effects.isNotEmpty) unawaited(game.audio.play('fall'));
    await Future.wait(effects);
    if (game.isActive && effects.isNotEmpty) unawaited(game.audio.play('land'));
  }

  Future<void> _animateReshuffle(domain.Board board, double duration) async {
    final effects = <Future<void>>[];
    for (final piece in _pieces.values) {
      final fade = OpacityEffect.fadeOut(
        EffectController(duration: duration * .7, curve: Curves.easeIn),
      );
      final shrink = ScaleEffect.to(
        Vector2.all(.72),
        EffectController(duration: duration * .7, curve: Curves.easeIn),
      );
      piece
        ..add(fade)
        ..add(shrink);
      effects.addAll([fade.completed, shrink.completed]);
    }
    await Future.wait(effects);
    await _rebuildFalling(board, duration * 1.25);
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
        reducedMotion: game.reducedMotion,
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

  Offset _center(domain.Position position) => Offset(
    (position.column + .5) * cellExtent,
    (position.row + .5) * cellExtent,
  );

  Vector2 _cellPosition(domain.Position position) =>
      Vector2(position.column * cellExtent, position.row * cellExtent);

  domain.Position? _positionAt(Vector2 local) {
    final column = (local.x / cellExtent).floor();
    final row = (local.y / cellExtent).floor();
    final position = domain.Position(row, column);
    return _board.contains(position) && _board.pieceAt(position) != null
        ? position
        : null;
  }

  void _select(domain.Position? position) {
    if (_selected != null) _pieces[_selected]?.isSelected = false;
    _selected = position;
    if (position != null) {
      _pieces[position]?.isSelected = true;
      unawaited(game.audio.play('select'));
    }
  }

  bool _hitsBlocker(Set<domain.Position> cleared) => cleared.any(
    (cell) => blockers.states.keys.any(
      (blocked) =>
          (blocked.row - cell.row).abs() +
              (blocked.column - cell.column).abs() <=
          1,
    ),
  );

  String _specialSound(domain.SpecialKind kind) => switch (kind) {
    domain.SpecialKind.sugarBeam => 'sugar_beam',
    domain.SpecialKind.goldenRecipeSpark => 'golden_spark',
    domain.SpecialKind.ovenBurst => 'oven_burst',
    domain.SpecialKind.peanutSpinner => 'peanut_spinner',
    domain.SpecialKind.peanutKisses => 'peanut_kisses',
  };
}

class _BoardMarkers extends PositionComponent {
  _BoardMarkers(this.board) : super(priority: 20);
  final BoardComponent board;

  @override
  void render(Canvas canvas) {
    final extent = board.cellExtent;
    final objectives = board.game.boardObjectives;
    for (final cell in objectives.recipeBaskets) {
      _badge(
        canvas,
        cell,
        ui.Icons.shopping_basket_rounded,
        const Color(0xFFFFD47D),
        extent,
      );
    }
    for (final cell in objectives.ovens) {
      final lit = objectives.litOvens.contains(cell);
      _badge(
        canvas,
        cell,
        ui.Icons.local_fire_department_rounded,
        lit ? const Color(0xFFFF9C62) : const Color(0xFFADB6B8),
        extent,
      );
    }
    for (final entry in board.blockers.states.entries) {
      if (entry.value.layers <= 1) continue;
      final origin = Offset(
        (entry.key.column + .78) * extent,
        (entry.key.row + .82) * extent,
      );
      canvas.drawCircle(
        origin,
        extent * .15,
        Paint()..color = const Color(0xF02B201D),
      );
      final text = ui.TextPainter(
        text: ui.TextSpan(
          text: '${entry.value.layers}',
          style: ui.TextStyle(
            fontFamily: 'Roboto',
            color: const Color(0xFFFFE3A0),
            fontSize: extent * .2,
            fontWeight: ui.FontWeight.w900,
          ),
        ),
        textDirection: ui.TextDirection.ltr,
      )..layout();
      text.paint(canvas, origin - Offset(text.width / 2, text.height / 2));
    }
  }

  void _badge(
    Canvas canvas,
    domain.Position cell,
    ui.IconData icon,
    Color color,
    double extent,
  ) {
    final origin = Offset(
      (cell.column + .78) * extent,
      (cell.row + .75) * extent,
    );
    canvas.drawCircle(
      origin,
      extent * .22,
      Paint()..color = const Color(0xF0253436),
    );
    canvas.drawCircle(
      origin,
      extent * .22,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
    final text = ui.TextPainter(
      text: ui.TextSpan(
        text: String.fromCharCode(icon.codePoint),
        style: ui.TextStyle(
          fontFamily: icon.fontFamily,
          package: icon.fontPackage,
          color: color,
          fontSize: extent * .31,
        ),
      ),
      textDirection: ui.TextDirection.ltr,
    )..layout();
    text.paint(canvas, origin - Offset(text.width / 2, text.height / 2));
  }
}
