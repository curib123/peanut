"""Generate deterministic original game sound effects using only Python stdlib."""

from __future__ import annotations

import math
import random
import struct
import wave
from pathlib import Path

RATE = 44_100
OUT = Path("assets/audio/sfx")


def synth(name: str, notes: list[tuple[float, float, float]], noise: float = 0.0) -> None:
    rng = random.Random(name)
    samples: list[int] = []
    for frequency, duration, volume in notes:
        count = int(RATE * duration)
        for index in range(count):
            time = index / RATE
            envelope = max(
                0.0, math.sin(math.pi * index / max(1, count - 1))
            ) ** 1.4
            tone = math.sin(2 * math.pi * frequency * time)
            tone += 0.28 * math.sin(4 * math.pi * frequency * time)
            tone += noise * rng.uniform(-1.0, 1.0)
            samples.append(int(max(-1, min(1, tone * envelope * volume)) * 32767))
    OUT.mkdir(parents=True, exist_ok=True)
    with wave.open(str(OUT / name), "wb") as output:
        output.setnchannels(1)
        output.setsampwidth(2)
        output.setframerate(RATE)
        output.writeframes(b"".join(struct.pack("<h", value) for value in samples))


def main() -> None:
    synth("swap.wav", [(420, 0.055, 0.28), (610, 0.07, 0.30)])
    synth("invalid.wav", [(260, 0.08, 0.24), (190, 0.12, 0.22)], noise=0.04)
    synth("match.wav", [(660, 0.06, 0.26), (880, 0.09, 0.28)])
    synth("cascade.wav", [(740, 0.05, 0.24), (990, 0.06, 0.27), (1240, 0.1, 0.25)])
    synth("special.wav", [(330, 0.07, 0.25), (660, 0.08, 0.28), (1320, 0.16, 0.23)], noise=0.03)
    synth("button.wav", [(520, 0.07, 0.22)])
    synth("win.wav", [(523, 0.1, 0.25), (659, 0.1, 0.26), (784, 0.1, 0.27), (1047, 0.24, 0.28)])
    synth("lose.wav", [(392, 0.13, 0.22), (330, 0.13, 0.22), (262, 0.28, 0.20)])
    synth("select.wav", [(760, 0.035, 0.16), (940, 0.04, 0.14)])
    synth("fall.wav", [(520, 0.035, 0.10), (430, 0.055, 0.11)])
    synth("land.wav", [(220, 0.035, 0.13)], noise=0.08)
    synth("shuffle.wav", [(360, 0.04, 0.16), (520, 0.04, 0.17), (740, 0.06, 0.18)], noise=0.05)
    synth("blocker_hit.wav", [(180, 0.055, 0.21), (130, 0.075, 0.18)], noise=0.24)
    synth("special_create.wav", [(620, 0.05, 0.18), (930, 0.07, 0.20), (1390, 0.1, 0.18)])
    synth("sugar_beam.wav", [(440, 0.05, 0.18), (880, 0.07, 0.20), (1760, 0.13, 0.18)], noise=0.05)
    synth("golden_spark.wav", [(990, 0.04, 0.15), (1320, 0.05, 0.18), (1980, 0.16, 0.17)])
    synth("oven_burst.wav", [(160, 0.06, 0.25), (90, 0.14, 0.22)], noise=0.42)
    synth("peanut_spinner.wav", [(480, 0.035, 0.15), (720, 0.035, 0.16), (960, 0.04, 0.17), (1200, 0.08, 0.18)])
    synth("peanut_kisses.wav", [(523, 0.06, 0.18), (659, 0.06, 0.19), (784, 0.08, 0.20), (1175, 0.15, 0.20)])
    print("Generated 19 original WAV sound effects.")


if __name__ == "__main__":
    main()
