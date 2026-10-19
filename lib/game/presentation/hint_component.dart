import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';

import '../domain/board.dart';
import '../domain/move_validator.dart';
import '../domain/position.dart';

typedef HintMove = ({Position first, Position second});

/// Searches once per idle period, using a copy of the presentation board.
class IdleHintController {
  IdleHintController({this.delay = 6});

  final double delay;
  double _idle = 0;
  bool _searched = false;
  HintMove? _move;

  HintMove? update(
    double dt, {
    required Board board,
    Set<Position> unavailableCells = const {},
    bool enabled = true,
  }) {
    if (!enabled) {
      reset();
      return null;
    }
    if (_searched) return _move;
    _idle += math.max(0, dt);
    if (_idle < delay) return null;
    _searched = true;
    final snapshot = board.copy();
    const validator = MoveValidator();
    for (final first in snapshot.positions) {
      for (final second in [
        Position(first.row, first.column + 1),
        Position(first.row + 1, first.column),
      ]) {
        if (validator.isValidSwap(
          snapshot,
          first,
          second,
          unavailableCells: unavailableCells,
        )) {
          return _move = (first: first, second: second);
        }
      }
    }
    return null;
  }

  void reset() {
    _idle = 0;
    _searched = false;
    _move = null;
  }
}

/// Two quiet corner outlines and a directional cue, in one canvas component.
class HintComponent extends PositionComponent {
  HintComponent({
    required this.move,
    required this.cellExtent,
    required super.size,
    required this.reducedMotion,
    this.visibleWhen,
  }) : super(priority: 25) {
    for (final cell in [move.first, move.second]) {
      final rect = Rect.fromLTWH(
        (cell.column + .085) * cellExtent,
        (cell.row + .085) * cellExtent,
        cellExtent * .83,
        cellExtent * .83,
      );
      final length = cellExtent * .19;
      _corners
        ..moveTo(rect.left, rect.top + length)
        ..lineTo(rect.left, rect.top)
        ..lineTo(rect.left + length, rect.top)
        ..moveTo(rect.right - length, rect.top)
        ..lineTo(rect.right, rect.top)
        ..lineTo(rect.right, rect.top + length)
        ..moveTo(rect.right, rect.bottom - length)
        ..lineTo(rect.right, rect.bottom)
        ..lineTo(rect.right - length, rect.bottom)
        ..moveTo(rect.left + length, rect.bottom)
        ..lineTo(rect.left, rect.bottom)
        ..lineTo(rect.left, rect.bottom - length);
    }
  }

  final HintMove move;
  final double cellExtent;
  final bool reducedMotion;
  final bool Function()? visibleWhen;
  final Path _corners = Path();
  double _elapsed = 0;

  @override
  void update(double dt) {
    super.update(dt);
    if (!reducedMotion) _elapsed += dt;
  }

  @override
  void render(Canvas canvas) {
    if (visibleWhen?.call() == false) return;
    final alpha = reducedMotion ? .9 : .7 + math.sin(_elapsed * 3) * .2;
    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, 0, size.x, size.y));
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = const Color(0xFF173936)
      ..strokeWidth = cellExtent * .075;
    canvas.drawPath(_corners, paint);
    canvas.drawPath(
      _corners,
      paint
        ..color = const Color(0xFFFFE6A0).withValues(alpha: alpha)
        ..strokeWidth = cellExtent * .035,
    );
    final first = Offset(
      (move.first.column + .5) * cellExtent,
      (move.first.row + .5) * cellExtent,
    );
    final second = Offset(
      (move.second.column + .5) * cellExtent,
      (move.second.row + .5) * cellExtent,
    );
    final direction = (second - first) / cellExtent;
    final middle = (first + second) / 2;
    final perpendicular = Offset(-direction.dy, direction.dx);
    final arrow = Path()
      ..moveTo(
        (middle -
                direction * cellExtent * .08 +
                perpendicular * cellExtent * .065)
            .dx,
        (middle -
                direction * cellExtent * .08 +
                perpendicular * cellExtent * .065)
            .dy,
      )
      ..lineTo(
        (middle + direction * cellExtent * .015).dx,
        (middle + direction * cellExtent * .015).dy,
      )
      ..lineTo(
        (middle -
                direction * cellExtent * .08 -
                perpendicular * cellExtent * .065)
            .dx,
        (middle -
                direction * cellExtent * .08 -
                perpendicular * cellExtent * .065)
            .dy,
      );
    canvas.drawPath(arrow, paint..strokeWidth = cellExtent * .035);
    if (!reducedMotion) {
      final t = (_elapsed % 2.4) / 2.4;
      canvas.drawCircle(
        Offset.lerp(first, second, t)!,
        cellExtent * .035,
        Paint()..color = const Color(0xFFB3F3DB).withValues(alpha: alpha),
      );
    }
    canvas.restore();
  }
}
