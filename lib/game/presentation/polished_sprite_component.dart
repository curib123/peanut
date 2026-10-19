import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flutter/painting.dart';

/// Adds a restrained living-game feel to static production sprites.
class PolishedSpriteComponent extends SpriteComponent {
  PolishedSpriteComponent({
    required super.sprite,
    required super.position,
    required super.size,
    this.reducedMotion = false,
    this.idleStrength = 1,
    super.priority,
  });

  final bool reducedMotion;
  final double idleStrength;
  double _time = 0;

  @override
  void update(double dt) {
    super.update(dt);
    if (!reducedMotion) _time += dt;
  }

  @override
  void render(Canvas canvas) {
    final phase = math.sin(_time * 2.1 + position.x * .017);
    final bob = reducedMotion ? 0.0 : phase * size.y * .018 * idleStrength;
    final breathe = reducedMotion ? 1.0 : 1 + phase * .012 * idleStrength;
    final bounds = Rect.fromLTWH(0, 0, size.x, size.y);
    canvas.save();
    canvas.translate(size.x / 2, size.y / 2 + bob);
    canvas.scale(breathe, breathe);
    canvas.translate(-size.x / 2, -size.y / 2);
    canvas.drawCircle(
      Offset(size.x / 2, size.y * .54),
      size.x * .37,
      Paint()
        ..color = const Color(0x22FFD56A)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
    final sweep = (_time + position.x * .019) % 8;
    final showShine = !reducedMotion && sweep < .8;
    if (showShine) canvas.saveLayer(bounds, Paint());
    super.render(canvas);
    if (showShine) {
      canvas.drawRect(
        bounds,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment(-1.4 + sweep * 3.4, -1),
            end: Alignment(-.8 + sweep * 3.4, 1),
            colors: const [
              Color(0x00FFFFFF),
              Color(0x88FFFFFF),
              Color(0x00FFFFFF),
            ],
            stops: const [.38, .5, .62],
          ).createShader(bounds)
          ..blendMode = BlendMode.srcATop,
      );
    }
    if (showShine) canvas.restore();
    canvas.restore();
  }
}
