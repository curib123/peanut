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
    List<Offset> targets = const [],
    required this.reducedMotion,
  }) : targets = List.unmodifiable(targets.take(16)),
       super(priority: 40) {
    for (var i = 0; i < this.targets.length; i++) {
      final target = this.targets[i];
      final control = Offset(
        (origin.dx + target.dx) / 2 + (i.isEven ? 1 : -1) * cellExtent * .4,
        math.min(origin.dy, target.dy) - cellExtent * (.5 + i % 3 * .2),
      );
      _routes.add(_PowerRoute(origin, control, target));
    }
  }

  final SpecialKind kind;
  final Offset origin;
  final double cellExtent;
  final bool vertical;
  final List<Offset> targets;
  final bool reducedMotion;
  final List<_PowerRoute> _routes = [];
  double _elapsed = 0;

  double get lifetime => reducedMotion ? .22 : .72;

  @override
  void update(double dt) {
    super.update(dt);
    _elapsed += dt;
    if (_elapsed >= lifetime) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    // Reduced motion uses one short, static power signature, without a flash.
    final t = reducedMotion ? .54 : (_elapsed / lifetime).clamp(0.0, 1.0);
    final alpha = reducedMotion ? .8 : math.pow(1 - t, .65).toDouble();
    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, 0, size.x, size.y));
    switch (kind) {
      case SpecialKind.sugarBeam:
        _beam(canvas, t, alpha);
      case SpecialKind.goldenRecipeSpark:
        _recipeSpark(canvas, t, alpha);
      case SpecialKind.ovenBurst:
        _ovenBurst(canvas, t, alpha);
      case SpecialKind.peanutSpinner:
        _spinner(canvas, t, alpha);
      case SpecialKind.peanutKisses:
        _kisses(canvas, t, alpha);
    }
    canvas.restore();
  }

  void _beam(Canvas canvas, double t, double alpha) {
    const color = Color(0xFF7EECED);
    final start = vertical ? Offset(origin.dx, 0) : Offset(0, origin.dy);
    final end = vertical
        ? Offset(origin.dx, size.y)
        : Offset(size.x, origin.dy);
    final width = cellExtent * (reducedMotion ? .12 : .3 * (1 - t) + .025);
    final paint = Paint()..strokeCap = StrokeCap.round;
    canvas.drawLine(
      start,
      end,
      paint
        ..color = color.withValues(alpha: alpha * .22)
        ..strokeWidth = width * 2.2,
    );
    canvas.drawLine(
      start,
      end,
      paint
        ..color = color.withValues(alpha: alpha * .85)
        ..strokeWidth = width,
    );
    canvas.drawLine(
      start,
      end,
      paint
        ..color = const Color(0xFFF0FFEC).withValues(alpha: alpha)
        ..strokeWidth = math.max(1.5, width * .22),
    );
    for (var i = -3; i <= 3; i++) {
      final point =
          origin +
          (vertical
              ? Offset(0, i * cellExtent * .8)
              : Offset(i * cellExtent * .8, 0));
      _star(canvas, point, cellExtent * .085, color.withValues(alpha: alpha));
    }
    _star(
      canvas,
      origin,
      cellExtent * (.22 + t * .15),
      const Color(0xFFFFFFFF).withValues(alpha: alpha),
    );
  }

  void _recipeSpark(Canvas canvas, double t, double alpha) {
    const gold = Color(0xFFFFD271);
    final travel = reducedMotion ? 1.0 : (t * 1.45).clamp(0.0, 1.0);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = cellExtent * .027
      ..color = gold.withValues(alpha: alpha * .4);
    for (final route in _routes) {
      canvas.drawPath(route.path, paint);
      for (var i = 2; i >= 0; i--) {
        final point = route.at((travel - i * .065).clamp(0.0, 1.0));
        _star(
          canvas,
          point,
          cellExtent * (i == 0 ? .12 : .05),
          (i == 0 ? const Color(0xFFFFF8D3) : gold).withValues(
            alpha: alpha * (1 - i * .25),
          ),
        );
      }
    }
    canvas.drawCircle(
      origin,
      cellExtent * (.2 + t * .45),
      Paint()
        ..color = gold.withValues(alpha: alpha * .7)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    _star(canvas, origin, cellExtent * .28, gold.withValues(alpha: alpha));
  }

  void _ovenBurst(Canvas canvas, double t, double alpha) {
    const orange = Color(0xFFFF934F);
    final radius = cellExtent * (.3 + t * 2.15);
    final paint = Paint()..color = orange.withValues(alpha: alpha * .13);
    canvas.drawCircle(origin, radius, paint);
    canvas.drawCircle(
      origin,
      radius,
      paint
        ..style = PaintingStyle.stroke
        ..strokeWidth = cellExtent * .07
        ..color = orange.withValues(alpha: alpha),
    );
    canvas.drawCircle(
      origin,
      radius * .7,
      paint
        ..strokeWidth = 1.5
        ..color = const Color(0xFFFFDF88).withValues(alpha: alpha * .8),
    );
    for (var i = 0; i < 10; i++) {
      final angle = i * math.pi / 5;
      final direction = Offset(math.cos(angle), math.sin(angle));
      final tip = origin + direction * (radius + cellExtent * .15);
      canvas.drawLine(
        origin + direction * radius * .7,
        tip,
        paint
          ..strokeCap = StrokeCap.round
          ..strokeWidth = cellExtent * .055
          ..color = orange.withValues(alpha: alpha),
      );
      _star(
        canvas,
        tip,
        cellExtent * .075,
        const Color(0xFFFFE5A7).withValues(alpha: alpha),
      );
    }
  }

  void _spinner(Canvas canvas, double t, double alpha) {
    const violet = Color(0xFFC4A2FF);
    final radius = cellExtent * (.3 + t * 1.05);
    final phase = reducedMotion ? .5 : t * math.pi * 3;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 3; i++) {
      final angle = phase + i * math.pi * 2 / 3;
      canvas.drawArc(
        Rect.fromCircle(center: origin, radius: radius),
        angle,
        math.pi * .46,
        false,
        paint
          ..strokeWidth = cellExtent * .085
          ..color = violet.withValues(alpha: alpha * .85),
      );
      final point = origin + Offset(math.cos(angle), math.sin(angle)) * radius;
      canvas.drawOval(
        Rect.fromCenter(
          center: point,
          width: cellExtent * .25,
          height: cellExtent * .14,
        ),
        Paint()..color = const Color(0xFFFFD68B).withValues(alpha: alpha),
      );
    }
    for (final route in _routes.take(6)) {
      canvas.drawPath(
        route.path,
        paint
          ..strokeWidth = 1.5
          ..color = violet.withValues(alpha: alpha * .45),
      );
      final point = route.at(reducedMotion ? 1 : (t * 1.4).clamp(0.0, 1.0));
      _star(
        canvas,
        point,
        cellExtent * .11,
        const Color(0xFFE2D6FF).withValues(alpha: alpha),
      );
    }
    canvas.drawCircle(
      origin,
      cellExtent * .15,
      Paint()..color = violet.withValues(alpha: alpha),
    );
  }

  void _kisses(Canvas canvas, double t, double alpha) {
    const pink = Color(0xFFFF9FBE);
    final radius = cellExtent * (.35 + t * 1.8);
    final paint = Paint()
      ..color = pink.withValues(alpha: alpha * .65)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(origin, radius * .7, paint);
    for (var i = 0; i < 8; i++) {
      final angle = i * math.pi / 4 - math.pi / 2;
      final point = origin + Offset(math.cos(angle), math.sin(angle)) * radius;
      final heart = _heart(point, cellExtent * (.14 + (1 - t) * .05));
      canvas.drawPath(heart, Paint()..color = pink.withValues(alpha: alpha));
      canvas.drawLine(
        origin + Offset(math.cos(angle), math.sin(angle)) * radius * .45,
        point,
        paint..color = pink.withValues(alpha: alpha * .35),
      );
    }
    _star(
      canvas,
      origin,
      cellExtent * .23,
      const Color(0xFFFFF1E6).withValues(alpha: alpha),
    );
  }

  void _star(Canvas canvas, Offset point, double radius, Color color) {
    canvas.drawPath(
      Path()
        ..moveTo(point.dx, point.dy - radius)
        ..lineTo(point.dx + radius * .3, point.dy - radius * .3)
        ..lineTo(point.dx + radius, point.dy)
        ..lineTo(point.dx + radius * .3, point.dy + radius * .3)
        ..lineTo(point.dx, point.dy + radius)
        ..lineTo(point.dx - radius * .3, point.dy + radius * .3)
        ..lineTo(point.dx - radius, point.dy)
        ..lineTo(point.dx - radius * .3, point.dy - radius * .3)
        ..close(),
      Paint()..color = color,
    );
  }

  Path _heart(Offset point, double radius) => Path()
    ..moveTo(point.dx, point.dy + radius)
    ..cubicTo(
      point.dx - radius * 2,
      point.dy - radius * .1,
      point.dx - radius * .8,
      point.dy - radius * 1.6,
      point.dx,
      point.dy - radius * .5,
    )
    ..cubicTo(
      point.dx + radius * .8,
      point.dy - radius * 1.6,
      point.dx + radius * 2,
      point.dy - radius * .1,
      point.dx,
      point.dy + radius,
    )
    ..close();
}

class _PowerRoute {
  _PowerRoute(this.origin, this.control, this.target) {
    path = Path()
      ..moveTo(origin.dx, origin.dy)
      ..quadraticBezierTo(control.dx, control.dy, target.dx, target.dy);
  }

  final Offset origin;
  final Offset control;
  final Offset target;
  late final Path path;

  Offset at(double t) =>
      origin * ((1 - t) * (1 - t)) +
      control * (2 * (1 - t) * t) +
      target * (t * t);
}

/// Draws at most 120 fading crumbs in one component, even for a board-wide clear.
class MatchSparklesComponent extends PositionComponent {
  MatchSparklesComponent({
    required Iterable<Offset> origins,
    required this.extent,
    Vector2? boardSize,
  }) : origins = origins.take(24).toList(growable: false),
       super(size: boardSize, priority: 35);
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
    canvas.save();
    if (size.x > 0 && size.y > 0) {
      canvas.clipRect(Rect.fromLTWH(0, 0, size.x, size.y));
    }
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
        final radius = extent * .04 * (1 - t * .7);
        if (i.isEven) {
          canvas.drawLine(
            p - Offset(math.cos(angle), math.sin(angle)) * radius * 3,
            p,
            paint
              ..strokeWidth = radius * 1.1
              ..strokeCap = StrokeCap.round,
          );
        } else {
          canvas.drawCircle(p, radius, paint);
        }
      }
    }
    canvas.restore();
  }
}
