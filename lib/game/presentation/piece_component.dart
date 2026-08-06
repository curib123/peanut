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

  static const _colors = {
    'peanut': Color(0xFFD99048),
    'egg': Color(0xFFFFE07A),
    'sugar_crystal': Color(0xFF72D5E8),
    'caramel_ribbon': Color(0xFFE87945),
    'coconut_cream': Color(0xFFF8F0DB),
    'cocoa_crumb': Color(0xFF75452F),
  };

  static const _labels = {
    'peanut': 'P',
    'egg': 'E',
    'sugar_crystal': 'S',
    'caramel_ribbon': 'C',
    'coconut_cream': 'N',
    'cocoa_crumb': 'O',
  };

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final center = Offset(size.x / 2, size.y / 2);
    final radius = size.x * 0.39;
    canvas.drawCircle(
      center + Offset(0, size.x * 0.06),
      radius,
      Paint()..color = const Color(0x26000000),
    );
    canvas.drawCircle(
      center,
      radius,
      Paint()..color = _colors[piece.kind.id] ?? const Color(0xFFE968A8),
    );
    if (piece.isSpecial) {
      canvas.drawCircle(
        center,
        radius * 0.82,
        Paint()
          ..color = const Color(0xCCFFF4B8)
          ..style = PaintingStyle.stroke
          ..strokeWidth = size.x * 0.08,
      );
    }
    canvas.drawCircle(
      center - Offset(size.x * 0.1, size.x * 0.1),
      radius * 0.25,
      Paint()..color = const Color(0x66FFFFFF),
    );
    if (isSelected) {
      canvas.drawCircle(
        center,
        radius + 3,
        Paint()
          ..color = const Color(0xFFFFC43D)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4,
      );
    }

    final label = switch (piece.specialKind) {
      SpecialKind.sugarBeam =>
        piece.beamOrientation == BeamOrientation.horizontal ? '—' : '|',
      SpecialKind.goldenRecipeSpark => '★',
      SpecialKind.ovenBurst => '✦',
      SpecialKind.peanutSpinner => '↻',
      null =>
        _labels[piece.kind.id] ?? piece.kind.id.substring(0, 1).toUpperCase(),
    };
    final painter = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          color: piece.kind.id == 'coconut_cream'
              ? const Color(0xFF5A3825)
              : const Color(0xFFFFFFFF),
          fontSize: size.x * 0.28,
          fontWeight: FontWeight.w900,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(
      canvas,
      center - Offset(painter.width / 2, painter.height / 2),
    );
  }
}
