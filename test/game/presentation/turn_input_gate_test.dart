import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:puff_and_crunch/game/presentation/turn_input_gate.dart';

void main() {
  test('input gate rejects a second turn until resolution completes', () async {
    final gate = TurnInputGate();
    final resolution = Completer<bool>();

    final first = gate.run(() => resolution.future);
    expect(gate.isLocked, isTrue);
    expect(await gate.run(() async => true), isNull);

    resolution.complete(true);
    expect(await first, isTrue);
    expect(gate.isLocked, isFalse);
    expect(await gate.run(() async => true), isTrue);
  });

  test('input gate unlocks after an animation failure', () async {
    final gate = TurnInputGate();

    await expectLater(
      gate.run<bool>(() => Future<bool>.error(StateError('animation failed'))),
      throwsStateError,
    );

    expect(gate.isLocked, isFalse);
  });
}
