"""Generate deterministic, seamless original background loops for Puff & Crunch."""

from __future__ import annotations

import math
import wave
from pathlib import Path

SAMPLE_RATE = 22_050
DURATION = 16
OUTPUT = Path("assets/audio/music")

TRACKS = {
    "main_theme": ([261.63, 329.63, 392.00, 523.25], 0.72),
    "sunrise_bakery": ([293.66, 369.99, 440.00, 587.33], 0.78),
    "peanut_grove": ([220.00, 277.18, 329.63, 440.00], 0.64),
    "egg_cloud_kitchen": ([329.63, 415.30, 493.88, 659.25], 0.82),
    "sugar_harbor": ([246.94, 311.13, 369.99, 493.88], 0.70),
    "festival_oven": ([196.00, 246.94, 293.66, 392.00], 0.58),
    "starlight_bake_off": ([277.18, 349.23, 415.30, 554.37], 0.88),
}


def sample(track: str, notes: list[float], warmth: float, index: int) -> float:
    t = index / SAMPLE_RATE
    beat = int(t * 2) % 8
    note = notes[(beat + (beat // 4)) % len(notes)]
    phase = (t * 2) % 1
    envelope = math.sin(math.pi * phase) ** 2
    bell = math.sin(2 * math.pi * note * phase * .5) * envelope
    base = round(notes[0] * .5 * DURATION) / DURATION
    soft = math.sin(2 * math.pi * base * t) * .28
    sparkle = math.sin(2 * math.pi * note * phase) * envelope * .18
    pulse = math.sin(2 * math.pi * 2 * t) * .06
    character = (sum(ord(char) for char in track) % 7) * .004
    return (bell * .34 + soft * warmth + sparkle + pulse + character) * .42


def write_track(name: str, notes: list[float], warmth: float) -> None:
    path = OUTPUT / f"{name}.wav"
    total = SAMPLE_RATE * DURATION
    frames = bytearray()
    for index in range(total):
        value = max(-1.0, min(1.0, sample(name, notes, warmth, index)))
        frames.extend(int(value * 32767).to_bytes(2, "little", signed=True))
    with wave.open(str(path), "wb") as output:
        output.setnchannels(1)
        output.setsampwidth(2)
        output.setframerate(SAMPLE_RATE)
        output.writeframes(frames)


def main() -> None:
    OUTPUT.mkdir(parents=True, exist_ok=True)
    for name, (notes, warmth) in TRACKS.items():
        write_track(name, notes, warmth)
        print(f"wrote {OUTPUT / f'{name}.wav'}")


if __name__ == "__main__":
    main()
