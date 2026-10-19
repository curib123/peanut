import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/painting.dart';

import '../domain/piece.dart';

class PieceComponent extends PositionComponent {
  PieceComponent({
    required this.piece,
    required super.position,
    required double extent,
    this.reducedMotion = false,
  }) : super(size: Vector2.all(extent), anchor: Anchor.topLeft);

  final Piece piece;
  final bool reducedMotion;
  Sprite? _sprite;
  double _elapsed = 0;
  bool _isSelected = false;

  bool get isSelected => _isSelected;
  set isSelected(bool value) {
    if (_isSelected == value) return;
    _isSelected = value;
    removeWhere((component) => component is ScaleEffect);
    scale = Vector2.all(1);
    if (value && !reducedMotion) {
      add(
        ScaleEffect.to(
          Vector2.all(1.09),
          EffectController(duration: .32, reverseDuration: .32, infinite: true),
        ),
      );
    }
  }

  static const _fallbackColors = {
    'peanut': Color(0xFFD99048),
    'egg': Color(0xFFFFE07A),
    'sugar_crystal': Color(0xFF72D5E8),
    'caramel_ribbon': Color(0xFFE87945),
    'coconut_cream': Color(0xFFF8F0DB),
    'cocoa_crumb': Color(0xFF75452F),
  };

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    try {
      _sprite = await Sprite.load(_spritePath());
    } catch (_) {
      _sprite = null;
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!reducedMotion) _elapsed += dt;
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final center = Offset(size.x / 2, size.y / 2);
    final radius = size.x * .39;
    if (_isSelected || piece.isSpecial) {
      final bounds = Rect.fromLTWH(
        size.x * .03,
        size.y * .03,
        size.x * .94,
        size.y * .94,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(bounds, Radius.circular(size.x * .22)),
        Paint()..color = Color(_isSelected ? 0x66FFE195 : 0x22FFCB65),
      );
      if (_isSelected) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(bounds, Radius.circular(size.x * .22)),
          Paint()
            ..color = const Color(0xFFFFE3A0)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.5,
        );
      }
    }
    canvas.drawOval(
      Rect.fromCenter(
        center: center + Offset(0, size.x * .32),
        width: size.x * .58,
        height: size.x * .13,
      ),
      Paint()..color = const Color(0x36000000),
    );
    final sprite = _sprite;
    if (sprite != null) {
      final phase = math.sin(_elapsed * 2.35 + piece.kind.id.hashCode % 17);
      final bob = reducedMotion ? 0.0 : phase * size.x * .022;
      final breathe = reducedMotion ? 1.0 : 1 + phase * .014;
      final bounds = Rect.fromLTWH(0, 0, size.x, size.y);
      canvas.save();
      canvas.translate(size.x / 2, size.y / 2 + bob);
      canvas.scale(breathe, breathe);
      canvas.translate(-size.x / 2, -size.y / 2);
      final sweep = (_elapsed + (piece.kind.id.hashCode % 11) * .37) % 7;
      final showShine = !reducedMotion && sweep < .85;
      if (showShine) canvas.saveLayer(bounds, Paint());
      sprite.render(
        canvas,
        position: Vector2.all(size.x * .03),
        size: Vector2.all(size.x * .94),
      );
      if (showShine) {
        canvas.drawRect(
          bounds,
          Paint()
            ..shader = LinearGradient(
              begin: Alignment(-1.5 + sweep * 3.2, -1),
              end: Alignment(-.7 + sweep * 3.2, 1),
              colors: const [
                Color(0x00FFFFFF),
                Color(0x99FFFFFF),
                Color(0x00FFFFFF),
              ],
              stops: const [.4, .5, .6],
            ).createShader(bounds)
            ..blendMode = BlendMode.srcATop,
        );
      }
      if (showShine) canvas.restore();
      canvas.restore();
    } else {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCircle(center: center, radius: radius),
          Radius.circular(size.x * .22),
        ),
        Paint()
          ..color = _fallbackColors[piece.kind.id] ?? const Color(0xFFE968A8),
      );
    }
  }

  String _spritePath() => switch (piece.specialKind) {
    SpecialKind.sugarBeam =>
      'specials/sugar_beam_${piece.beamOrientation == BeamOrientation.vertical ? 'vertical' : 'horizontal'}.png',
    SpecialKind.goldenRecipeSpark => 'specials/golden_recipe_spark.png',
    SpecialKind.ovenBurst => 'specials/oven_burst.png',
    SpecialKind.peanutSpinner => 'specials/peanut_spinner.png',
    SpecialKind.peanutKisses => 'specials/peanut_kisses.png',
    null => 'pieces/${piece.kind.id}.png',
  };
}
