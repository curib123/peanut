"""Render the game's original, deterministic tropical bakery sound palette.

Only Python's standard library is required. Warm wooden mallets, soft dough
pops, sugar-glass bells and filtered air share a major-pentatonic tuning.
Run from any directory: python path/to/tool/generate_sfx.py.
"""

from __future__ import annotations

import math
import random
import struct
import wave
from pathlib import Path

RATE = 44_100
OUT = Path(__file__).resolve().parents[1] / "assets/audio/sfx"
TAU = 2 * math.pi


class Cue:
    def __init__(self, name: str, duration: float, peak: float = 0.46) -> None:
        self.name = name
        self.peak = peak
        self.left = [0.0] * round(RATE * duration)
        self.right = [0.0] * len(self.left)
        self.rng = random.Random(name)

    def tone(
        self, start: float, duration: float, frequency: float, gain: float,
        *, kind: str = "wood", pan: float = 0.0, end: float | None = None,
        attack: float = 0.003,
    ) -> None:
        """Add a plucked/swept voice with continuous phase and smooth edges."""
        first = round((start + 0.003) * RATE)
        count = min(round(duration * RATE), len(self.left) - first)
        if kind == "bell":
            partials = ((1, 0.80), (2.002, 0.24), (3.01, 0.12), (4.16, 0.035))
        elif kind == "wood":
            partials = ((1, 0.85), (2.01, 0.20), (3.98, 0.12))
        else:
            partials = ((1, 0.94), (2, 0.10), (3, 0.035))
        sweep = math.log((end or frequency) / frequency) / duration
        left_gain = gain * math.sqrt((1 - pan) / 2)
        right_gain = gain * math.sqrt((1 + pan) / 2)
        for index in range(count):
            time = index / RATE
            position = time / duration
            phase = TAU * frequency * (
                math.expm1(sweep * time) / sweep if abs(sweep) > 0.0001 else time
            )
            envelope = math.sin(min(1.0, time / attack) * math.pi / 2) ** 2
            envelope *= min(1.0, (duration - time) / 0.014) ** 2
            envelope *= math.exp(-position * (4.8 if kind == "wood" else 3.3))
            tone = 0.0
            for ratio, weight in partials:
                if max(frequency, end or frequency) * ratio < RATE * 0.44:
                    # Upper partials decay sooner, like a real struck object.
                    tone += weight * math.sin(phase * ratio) * math.exp(
                        -position * (ratio - 1) * 1.35
                    )
            self.left[first + index] += tone * envelope * left_gain
            self.right[first + index] += tone * envelope * right_gain

    def air(
        self, start: float, duration: float, gain: float, *, pan: float = 0.0,
        brightness: float = 0.12, flutter: float = 0.0,
    ) -> None:
        """Add softly filtered shaker/oven air, never raw full-band hiss."""
        first = round((start + 0.003) * RATE)
        count = min(round(duration * RATE), len(self.left) - first)
        low = 0.0
        low2 = 0.0
        for index in range(count):
            position = index / max(1, count - 1)
            low += brightness * (self.rng.uniform(-1.0, 1.0) - low)
            low2 += brightness * (low - low2)
            envelope = math.sin(math.pi * position) ** 1.4
            envelope *= math.exp(-1.3 * position)
            envelope *= 1 - flutter * (0.5 + 0.5 * math.cos(TAU * position * 5))
            value = low2 * gain * envelope
            self.left[first + index] += value * math.sqrt((1 - pan) / 2)
            self.right[first + index] += value * math.sqrt((1 + pan) / 2)

    def notes(
        self, frequencies: tuple[float, ...], *, start: float = 0.0,
        step: float = 0.045, duration: float = 0.20, gain: float = 0.45,
        kind: str = "wood",
    ) -> None:
        for index, frequency in enumerate(frequencies):
            pan = (index % 3 - 1) * 0.24
            self.tone(start + index * step, duration, frequency, gain,
                      kind=kind, pan=pan)

    def export(self) -> None:
        """Add small room reflections, remove DC and leave mixing headroom."""
        dry_left, dry_right = self.left[:], self.right[:]
        for channel, other, delay, amount in (
            (self.left, dry_right, 0.017, 0.11),
            (self.right, dry_left, 0.026, 0.10),
        ):
            offset = round(delay * RATE)
            for index in range(offset, len(channel)):
                channel[index] += other[index - offset] * amount

        for channel in (self.left, self.right):
            previous_input = previous_output = 0.0
            for index, value in enumerate(channel):
                filtered = value - previous_input + 0.995 * previous_output
                previous_input, previous_output = value, filtered
                edge = min(1.0, index / 132, (len(channel) - 1 - index) / 441)
                channel[index] = math.tanh(filtered * 1.25) * edge
            channel[:88] = [0.0] * 88
            channel[-88:] = [0.0] * 88

        loudest = max(max(map(abs, self.left)), max(map(abs, self.right)), 0.001)
        scale = self.peak / loudest
        pcm = bytearray()
        for left, right in zip(self.left, self.right):
            pcm.extend(struct.pack("<hh", round(left * scale * 32767),
                                   round(right * scale * 32767)))
        OUT.mkdir(parents=True, exist_ok=True)
        with wave.open(str(OUT / self.name), "wb") as output:
            output.setnchannels(2)
            output.setsampwidth(2)
            output.setframerate(RATE)
            output.writeframes(pcm)


def make_cues() -> list[Cue]:
    cues: list[Cue] = []

    cue = Cue("button.wav", 0.115, 0.29)
    cue.tone(0, 0.070, 470, 0.55, end=610)
    cue.tone(0.013, 0.070, 1220, 0.10, kind="bell", pan=0.16)
    cues.append(cue)

    cue = Cue("select.wav", 0.135, 0.28)
    cue.tone(0, 0.065, 730, 0.40, kind="soft", end=1050)
    cue.tone(0.018, 0.085, 1568, 0.12, kind="bell", pan=-0.20)
    cues.append(cue)

    cue = Cue("swap.wav", 0.205, 0.36)
    cue.air(0, 0.120, 0.32, brightness=0.08, pan=-0.15)
    cue.tone(0, 0.100, 390, 0.32, end=620, kind="soft", pan=-0.25)
    cue.tone(0.045, 0.120, 784, 0.38, pan=0.25)
    cues.append(cue)

    cue = Cue("invalid.wav", 0.285, 0.35)
    cue.tone(0, 0.130, 330, 0.45, end=260, kind="soft", pan=-0.12)
    cue.tone(0.085, 0.155, 262, 0.30, end=220, kind="wood", pan=0.12)
    cue.air(0, 0.100, 0.12)
    cues.append(cue)

    cue = Cue("match.wav", 0.345, 0.46)
    cue.notes((659.25, 783.99, 1046.50), step=0.035, duration=0.22, gain=0.43)
    cue.tone(0.035, 0.210, 1567.98, 0.12, kind="bell", pan=0.30)
    cue.tone(0, 0.055, 180, 0.13, end=100, kind="soft")
    cues.append(cue)

    cue = Cue("cascade.wav", 0.430, 0.48)
    cue.notes((783.99, 1046.50, 1318.51, 1567.98), step=0.045,
              duration=0.24, gain=0.35, kind="bell")
    cue.tone(0, 0.130, 392, 0.24, end=523.25)
    cues.append(cue)

    cue = Cue("fall.wav", 0.170, 0.23)
    cue.air(0, 0.115, 0.26, brightness=0.06, pan=-0.15)
    cue.tone(0, 0.125, 740, 0.24, end=330, kind="soft", attack=0.008)
    cues.append(cue)

    cue = Cue("land.wav", 0.145, 0.29)
    cue.tone(0, 0.095, 185, 0.55, end=90, kind="wood")
    cue.tone(0.004, 0.050, 660, 0.13, kind="wood", pan=0.1)
    cue.air(0, 0.048, 0.30, brightness=0.22)
    cues.append(cue)

    cue = Cue("shuffle.wav", 0.465, 0.40)
    cue.air(0, 0.370, 0.70, brightness=0.18, flutter=0.7)
    cue.notes((392, 523.25, 659.25, 783.99, 1046.50), step=0.055,
              duration=0.150, gain=0.25)
    cues.append(cue)

    cue = Cue("blocker_hit.wav", 0.225, 0.43)
    cue.tone(0, 0.125, 205, 0.50, end=125)
    cue.tone(0.008, 0.095, 710, 0.18, pan=-0.20)
    cue.tone(0.025, 0.110, 460, 0.12, pan=0.25)
    cue.air(0, 0.075, 0.85, brightness=0.40)
    cues.append(cue)

    cue = Cue("special_create.wav", 0.510, 0.48)
    cue.notes((659.25, 1046.50, 1318.51, 2093), step=0.045,
              duration=0.270, gain=0.32, kind="bell")
    cue.tone(0, 0.240, 330, 0.22, end=660, kind="soft", attack=0.020)
    cue.air(0.025, 0.280, 0.23, brightness=0.08)
    cues.append(cue)

    cue = Cue("special.wav", 0.640, 0.52)
    cue.tone(0, 0.330, 262, 0.28, end=1046.50, kind="soft", attack=0.015)
    cue.notes((523.25, 783.99, 1046.50, 1567.98), start=0.080,
              step=0.060, duration=0.300, gain=0.30, kind="bell")
    cue.air(0.020, 0.380, 0.38, brightness=0.10)
    cues.append(cue)

    cue = Cue("sugar_beam.wav", 0.505, 0.50)
    cue.tone(0, 0.310, 440, 0.33, end=1760, kind="soft", attack=0.009)
    cue.tone(0.020, 0.270, 880, 0.10, end=2640, kind="bell", pan=-0.25)
    cue.notes((1318.51, 2093), start=0.110, step=0.080,
              duration=0.230, gain=0.22, kind="bell")
    cue.air(0, 0.300, 0.35, brightness=0.16, pan=0.24)
    cues.append(cue)

    cue = Cue("golden_spark.wav", 0.550, 0.47)
    cue.notes((1046.50, 1567.98, 2093, 2637.02), step=0.050,
              duration=0.320, gain=0.30, kind="bell")
    cue.tone(0, 0.140, 523.25, 0.22, end=783.99)
    cues.append(cue)

    cue = Cue("oven_burst.wav", 0.420, 0.53)
    cue.tone(0, 0.270, 150, 0.60, end=58, kind="soft", attack=0.004)
    cue.tone(0.010, 0.160, 310, 0.18, end=170)
    cue.air(0, 0.280, 1.50, brightness=0.11, flutter=0.13)
    cue.notes((523.25, 783.99), start=0.075, step=0.060,
              duration=0.170, gain=0.16, kind="bell")
    cues.append(cue)

    cue = Cue("peanut_spinner.wav", 0.505, 0.46)
    cue.notes((523.25, 659.25, 783.99, 1046.50, 1318.51, 1567.98),
              step=0.041, duration=0.210, gain=0.28)
    cue.air(0, 0.310, 0.65, brightness=0.18, flutter=0.8)
    cues.append(cue)

    cue = Cue("peanut_kisses.wav", 0.705, 0.52)
    cue.notes((523.25, 659.25, 783.99, 1046.50, 1567.98), step=0.063,
              duration=0.340, gain=0.32, kind="bell")
    cue.notes((261.63, 392), step=0.126, duration=0.280, gain=0.27)
    cue.air(0.075, 0.360, 0.25, brightness=0.07)
    cues.append(cue)

    cue = Cue("win.wav", 1.080, 0.56)
    cue.notes((523.25, 659.25, 783.99, 1046.50, 1318.51), step=0.105,
              duration=0.390, gain=0.40)
    cue.notes((1046.50, 1318.51, 1567.98, 2093), start=0.380, step=0.055,
              duration=0.430, gain=0.21, kind="bell")
    cue.notes((261.63, 392, 523.25), start=0.025, step=0.210,
              duration=0.290, gain=0.29)
    cues.append(cue)

    cue = Cue("lose.wav", 0.815, 0.39)
    cue.notes((659.25, 523.25, 392, 261.63), step=0.130,
              duration=0.340, gain=0.35, kind="wood")
    cue.tone(0.400, 0.340, 523.25, 0.11, kind="bell", pan=0.2)
    cues.append(cue)
    return cues


def main() -> None:
    cues = make_cues()
    for cue in cues:
        cue.export()
    print(f"Generated {len(cues)} original layered stereo WAV sound effects.")


if __name__ == "__main__":
    main()
