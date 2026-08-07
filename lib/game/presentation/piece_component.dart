import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/painting.dart';

import '../domain/piece.dart';

class PieceComponent extends PositionComponent {
  PieceComponent({
    required this.piece,
    required super.position,
    required double extent,
  }) : super(size: Vector2.all(extent), anchor: Anchor.topLeft);

  final Piece piece;
  Sprite? _sprite;
  bool _isSelected = false;

  bool get isSelected => _isSelected;
  set isSelected(bool value) {
    if (_isSelected == value) return;
    _isSelected = value;
    removeWhere((component) => component is ScaleEffect);
    scale = Vector2.all(1);
    if (value) {
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
  void render(Canvas canvas) {
    super.render(canvas);
    final center = Offset(size.x / 2, size.y / 2);
    final radius = size.x * .39;
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
      sprite.render(
        canvas,
        position: Vector2.all(size.x * .03),
        size: Vector2.all(size.x * .94),
      );
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
    if (isSelected) {
      canvas.drawCircle(
        center,
        radius + 3,
        Paint()
          ..color = const Color(0xFFFFD65A)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4,
      );
    }
  }

  String _spritePath() => switch (piece.specialKind) {
    SpecialKind.sugarBeam =>
      'specials/sugar_beam_${piece.beamOrientation == BeamOrientation.vertical ? 'vertical' : 'horizontal'}.png',
    SpecialKind.goldenRecipeSpark => 'specials/golden_recipe_spark.png',
    SpecialKind.ovenBurst => 'specials/oven_burst.png',
    SpecialKind.peanutSpinner => 'specials/peanut_spinner.png',
    null => 'pieces/${piece.kind.id}.png',
  };
}
