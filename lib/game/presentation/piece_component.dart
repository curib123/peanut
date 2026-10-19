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
    priority = value ? 5 : 0;
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
    final specialColor = _powerColor;
    if (_isSelected || piece.isSpecial) {
      final bounds = Rect.fromLTWH(
        size.x * .03,
        size.y * .03,
        size.x * .94,
        size.y * .94,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(bounds, Radius.circular(size.x * .22)),
        Paint()
          ..color = _isSelected
              ? const Color(0x44FFE195)
              : specialColor!.withValues(alpha: .14),
      );
      if (_isSelected) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(bounds, Radius.circular(size.x * .22)),
          Paint()
            ..color = const Color(0xFFFFE3A0)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.3,
        );
        final pulse = reducedMotion ? 0.0 : math.sin(_elapsed * 5) * .5 + .5;
        final inset = size.x * (.065 + pulse * .012);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            bounds.deflate(inset),
            Radius.circular(size.x * .17),
          ),
          Paint()
            ..color = const Color(0xFFFFF6CE).withValues(alpha: .5 + pulse * .3)
            ..style = PaintingStyle.stroke
            ..strokeWidth = .8,
        );
        _glint(canvas, Offset(size.x * .12, size.y * .12), size.x * .075, 1);
      }
    }
    if (specialColor != null) {
      final phase = reducedMotion ? 0.0 : _elapsed * .65;
      for (var i = 0; i < 3; i++) {
        canvas.drawArc(
          Rect.fromCircle(center: center, radius: size.x * .405),
          phase + i * math.pi * 2 / 3,
          math.pi * .38,
          false,
          Paint()
            ..color = specialColor.withValues(alpha: .65)
            ..style = PaintingStyle.stroke
            ..strokeCap = StrokeCap.round
            ..strokeWidth = size.x * .023,
        );
      }
    }
    canvas.drawOval(
      Rect.fromCenter(
        center: center + Offset(0, size.x * .32),
        width: size.x * .58,
        height: size.x * .13,
      ),
      Paint()..color = const Color(0x4D08191B),
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: center + Offset(0, size.x * .33),
        width: size.x * .39,
        height: size.x * .06,
      ),
      Paint()..color = const Color(0x4A061315),
    );
    final sprite = _sprite;
    if (sprite != null) {
      final phase = math.sin(_elapsed * 2.35 + piece.kind.id.hashCode % 17);
      final bob = reducedMotion ? 0.0 : phase * size.x * .022;
      final breathe = reducedMotion ? 1.0 : 1 + phase * .014;
      canvas.save();
      canvas.translate(size.x / 2, size.y / 2 + bob);
      canvas.scale(breathe, breathe);
      canvas.translate(-size.x / 2, -size.y / 2);
      final sweep = (_elapsed + (piece.kind.id.hashCode % 11) * .37) % 7;
      sprite.render(
        canvas,
        position: Vector2.all(size.x * .03),
        size: Vector2.all(size.x * .94),
      );
      if (!reducedMotion && sweep < .85) {
        _glint(
          canvas,
          Offset(size.x * .68, size.y * .26),
          size.x * .055,
          math.sin(sweep / .85 * math.pi),
        );
      }
      canvas.restore();
    } else {
      final color = _fallbackColors[piece.kind.id] ?? const Color(0xFFE968A8);
      final bounds = Rect.fromCircle(center: center, radius: radius);
      canvas.drawRRect(
        RRect.fromRectAndRadius(bounds, Radius.circular(size.x * .22)),
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color.lerp(color, const Color(0xFFFFFFFF), .3)!, color],
          ).createShader(bounds),
      );
      _glint(canvas, Offset(size.x * .32, size.y * .28), size.x * .07, .75);
    }
  }

  Color? get _powerColor => switch (piece.specialKind) {
    SpecialKind.sugarBeam => const Color(0xFF7EECED),
    SpecialKind.goldenRecipeSpark => const Color(0xFFFFD271),
    SpecialKind.ovenBurst => const Color(0xFFFF934F),
    SpecialKind.peanutSpinner => const Color(0xFFC4A2FF),
    SpecialKind.peanutKisses => const Color(0xFFFF9FBE),
    null => null,
  };

  void _glint(Canvas canvas, Offset center, double radius, double alpha) {
    final paint = Paint()
      ..color = const Color(0xFFFFF9DE).withValues(alpha: alpha)
      ..strokeWidth = size.x * .02
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      center - Offset(radius, 0),
      center + Offset(radius, 0),
      paint,
    );
    canvas.drawLine(
      center - Offset(0, radius),
      center + Offset(0, radius),
      paint,
    );
    canvas.drawCircle(center, radius * .3, paint);
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
