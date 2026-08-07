import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/flame.dart';

/// Plays the eight-frame AI-authored match burst sprite sheet once.
class MatchBurstComponent extends PositionComponent {
  MatchBurstComponent({
    required super.position,
    required super.size,
    required this.reducedMotion,
  }) : super(anchor: Anchor.center, priority: 30);

  final bool reducedMotion;
  final List<Sprite> _frames = [];
  double _elapsed = 0;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    final image = await Flame.images.load('effects/match_burst_sheet.png');
    final frameSize = Vector2(image.width / 4, image.height / 2);
    for (var row = 0; row < 2; row++) {
      for (var column = 0; column < 4; column++) {
        _frames.add(
          Sprite(
            image,
            srcPosition: Vector2(column * frameSize.x, row * frameSize.y),
            srcSize: frameSize,
          ),
        );
      }
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    _elapsed += dt;
    if (_elapsed >= (reducedMotion ? .18 : .48)) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    if (_frames.isEmpty) return;
    final progress = (_elapsed / (reducedMotion ? .18 : .48)).clamp(0.0, .999);
    final frame = reducedMotion ? 3 : (progress * _frames.length).floor();
    _frames[frame].render(canvas, size: size);
  }
}
