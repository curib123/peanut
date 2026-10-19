import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flutter/painting.dart' as ui;

import '../domain/turn_engine.dart';

/// A presentation-only receipt for one cascade. The session owns the score.
class ScorePopupComponent extends PositionComponent {
  ScorePopupComponent({
    required this.score,
    required this.cascadeMultiplier,
    required Vector2 origin,
    required this.cellExtent,
    required this.reducedMotion,
  }) : assert(score >= 0),
       assert(cascadeMultiplier > 0),
       _origin = origin.clone(),
       super(
         position: origin.clone(),
         size: Vector2(cellExtent * 2.5, cellExtent * .93),
         anchor: Anchor.center,
         priority: 55,
       );

  factory ScorePopupComponent.forCascade({
    required CascadeFrame cascade,
    required int cascadeIndex,
    required Vector2 origin,
    required double cellExtent,
    required bool reducedMotion,
  }) {
    assert(cascadeIndex >= 0);
    // Keep the receipt identical to LevelSession.play, including power bonuses.
    return ScorePopupComponent(
      score:
          cascade.matched.length * 60 * (cascadeIndex + 1) +
          cascade.activatedSpecials.length * 250,
      cascadeMultiplier: cascadeIndex + 1,
      origin: origin,
      cellExtent: cellExtent,
      reducedMotion: reducedMotion,
    );
  }

  final int score;
  final int cascadeMultiplier;
  final double cellExtent;
  final bool reducedMotion;
  final Vector2 _origin;
  double _elapsed = 0;
  ui.TextPainter? _scoreText;
  ui.TextPainter? _scoreOutline;
  ui.TextPainter? _caption;

  double get lifetime => reducedMotion ? .8 : 1.15;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    final fontSize = cellExtent * (score >= 10000 ? .36 : .44);
    _scoreText = _text('+$score', fontSize, const Color(0xFFFFF5CC));
    _scoreOutline = _text(
      '+$score',
      fontSize,
      const Color(0xFF3B241D),
      outline: true,
    );
    _caption = _text(
      cascadeMultiplier == 1 ? 'SWEET MATCH' : 'CASCADE ×$cascadeMultiplier',
      cellExtent * .145,
      cascadeMultiplier == 1
          ? const Color(0xFFFFD783)
          : const Color(0xFF9AF2E2),
    );
  }

  @override
  void update(double dt) {
    super.update(dt);
    _elapsed += dt;
    if (_elapsed >= lifetime) {
      removeFromParent();
      return;
    }
    if (reducedMotion) return;
    final t = (_elapsed / lifetime).clamp(0.0, 1.0);
    position.setFrom(_origin - Vector2(0, cellExtent * .75 * t));
    final entrance = (_elapsed / .18).clamp(0.0, 1.0);
    final pop = 1 + math.sin(entrance * math.pi) * .14;
    scale.setAll(pop);
  }

  @override
  void render(Canvas canvas) {
    final text = _scoreText;
    final caption = _caption;
    if (text == null || caption == null) return;
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.x, size.y),
      Radius.circular(cellExtent * .24),
    );
    canvas.drawRRect(
      rect.shift(Offset(0, cellExtent * .055)),
      Paint()..color = const Color(0x550C1819),
    );
    canvas.drawRRect(rect, Paint()..color = const Color(0xF52A4140));
    canvas.drawRRect(
      rect,
      Paint()
        ..color = const Color(0xFFFFD783)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
    caption.paint(
      canvas,
      Offset((size.x - caption.width) / 2, cellExtent * .11),
    );
    final textPosition = Offset((size.x - text.width) / 2, cellExtent * .28);
    _scoreOutline!.paint(canvas, textPosition);
    text.paint(canvas, textPosition);
  }

  ui.TextPainter _text(
    String value,
    double fontSize,
    Color color, {
    bool outline = false,
  }) => ui.TextPainter(
    text: ui.TextSpan(
      text: value,
      style: ui.TextStyle(
        fontFamily: 'Roboto',
        fontSize: fontSize,
        fontWeight: ui.FontWeight.w900,
        letterSpacing: .15,
        foreground: Paint()
          ..color = color
          ..style = outline ? PaintingStyle.stroke : PaintingStyle.fill
          ..strokeWidth = 3,
      ),
    ),
    textDirection: ui.TextDirection.ltr,
  )..layout();

  @override
  void onRemove() {
    _scoreText?.dispose();
    _scoreOutline?.dispose();
    _caption?.dispose();
    super.onRemove();
  }
}
