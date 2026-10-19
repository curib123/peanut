import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:puff_and_crunch/game/domain/piece.dart';
import 'package:puff_and_crunch/game/presentation/piece_component.dart';

void main() {
  test('reduced motion selection stays static', () {
    final piece = PieceComponent(
      piece: const Piece(PieceKind.peanut),
      position: Vector2.zero(),
      extent: 48,
      reducedMotion: true,
    );
    piece.isSelected = true;
    expect(piece.children.whereType<ScaleEffect>(), isEmpty);
    expect(piece.isSelected, isTrue);
  });
}
