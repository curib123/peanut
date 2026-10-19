import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';

import '../domain/piece.dart';

/// One bounded canvas layer per activated power; no full-screen blur or flash.
class PowerEffectComponent extends PositionComponent {
  PowerEffectComponent({
    required this.kind,
    required this.origin,
    required super.size,
    required this.cellExtent,
    this.vertical = false,
    this.targets = const [],
    required this.reducedMotion,
  }) : super(priority: 40);

  final SpecialKind kind;
  final Offset origin;
  final double cellExtent;
  final bool vertical;
  final List<Offset> targets;
  final bool reducedMotion;
  double _elapsed = 0;

  @override
  void update(double dt) {
    super.update(dt);
    _elapsed += dt;
    if (_elapsed >= (reducedMotion ? .15 : .55)) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final t = (_elapsed / (reducedMotion ? .15 : .55)).clamp(0.0, 1.0);
    final alpha = (1 - t) * .85;
    final color = kind == SpecialKind.goldenRecipeSpark
        ? const Color(0xFF97EEFF)
        : kind == SpecialKind.peanutKisses
        ? const Color(0xFFFFA0BF)
        : const Color(0xFFFFD783);
    final paint = Paint()
      ..color = color.withValues(alpha: alpha)
      ..strokeCap = StrokeCap.round;
    if (kind == SpecialKind.sugarBeam) {
      final start = vertical ? Offset(origin.dx, 0) : Offset(0, origin.dy);
      final end = vertical
          ? Offset(origin.dx, size.y)
          : Offset(size.x, origin.dy);
      canvas.drawLine(
        start,
        end,
        paint..strokeWidth = reducedMotion ? 3 : cellExtent * .24 * (1 - t),
      );
      canvas.drawLine(
        start,
        end,
        Paint()
          ..color = const Color(0xFFFFF8D8).withValues(alpha: alpha)
          ..strokeWidth = 2,
      );
    } else if (kind == SpecialKind.ovenBurst ||
        kind == SpecialKind.peanutKisses) {
      final radius = cellExtent * (reducedMotion ? .75 : .3 + t * 2.4);
      canvas.drawCircle(
        origin,
        radius,
        paint
          ..style = PaintingStyle.stroke
          ..strokeWidth = cellExtent * .09 * (1 - t),
      );
      canvas.drawCircle(origin, radius * .6, paint..strokeWidth = 2);
    } else {
      for (final target in targets.take(16)) {
        final control = Offset(
          (origin.dx + target.dx) / 2,
          math.min(origin.dy, target.dy) - cellExtent * .6,
        );
        final path = Path()
          ..moveTo(origin.dx, origin.dy)
          ..quadraticBezierTo(control.dx, control.dy, target.dx, target.dy);
        canvas.drawPath(
          path,
          paint
            ..style = PaintingStyle.stroke
            ..strokeWidth = reducedMotion ? 1 : 2.5,
        );
        final p = reducedMotion
            ? target
            : Offset(
                (1 - t) * (1 - t) * origin.dx +
                    2 * (1 - t) * t * control.dx +
                    t * t * target.dx,
                (1 - t) * (1 - t) * origin.dy +
                    2 * (1 - t) * t * control.dy +
                    t * t * target.dy,
              );
        canvas.drawCircle(
          p,
          cellExtent * .065,
          Paint()..color = const Color(0xFFFFF2C7).withValues(alpha: alpha),
        );
      }
    }
  }
}

/// Draws at most 120 fading crumbs in one component, even for a board-wide clear.
class MatchSparklesComponent extends PositionComponent {
  MatchSparklesComponent({
    required Iterable<Offset> origins,
    required this.extent,
  }) : origins = origins.take(24).toList(growable: false),
       super(priority: 35);
  final List<Offset> origins;
  final double extent;
  double _elapsed = 0;
  static const _colors = [
    Color(0xFFFFD47D),
    Color(0xFF9CE8F4),
    Color(0xFFFFB1C6),
  ];

  @override
  void update(double dt) {
    super.update(dt);
    _elapsed += dt;
    if (_elapsed >= .48) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final t = (_elapsed / .48).clamp(0.0, 1.0);
    final paint = Paint();
    for (var j = 0; j < origins.length; j++) {
      for (var i = 0; i < 5; i++) {
        final angle = i * math.pi * .4 + j * .47;
        final distance = extent * (.1 + t * .7);
        final p =
            origins[j] +
            Offset(
              math.cos(angle) * distance,
              math.sin(angle) * distance + t * t * extent * .5,
            );
        paint.color = _colors[(i + j) % _colors.length].withValues(
          alpha: 1 - t,
        );
        canvas.drawCircle(p, extent * .04 * (1 - t * .7), paint);
      }
    }
  }
}
