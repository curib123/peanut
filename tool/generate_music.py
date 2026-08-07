"""Generate deterministic, seamless original background loops for Puff & Crunch."""

from __future__ import annotations

import math
import wave
from pathlib import Path

SAMPLE_RATE = 22_050
DURATION = 24
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


def voice(frequency: float, time: float, brightness: float = 0.25) -> float:
    return (
        math.sin(2 * math.pi * frequency * time)
        + math.sin(4 * math.pi * frequency * time) * brightness
        + math.sin(6 * math.pi * frequency * time) * brightness * 0.24
    )


def sample(track: str, notes: list[float], warmth: float, index: int) -> tuple[float, float]:
    t = index / SAMPLE_RATE
    beat_length = .5
    beat_position = (t / beat_length) % 1
    beat = int(t / beat_length) % 48
    bar = beat // 4
    chord_root = notes[(bar // 2) % len(notes)]

    # Soft marimba lead with a quick, rounded decay.
    melody_steps = (0, 2, 1, 3, 2, 1, 3, 0)
    melody = notes[melody_steps[beat % len(melody_steps)]] * (2 if beat % 8 in (3, 7) else 1)
    pluck_env = math.exp(-beat_position * 6.5) * math.sin(math.pi * min(1, beat_position * 5))
    pluck = voice(melody, t, .32) * pluck_env * .20

    # Warm sustained bakery-organ chord bed.
    fade = .5 - .5 * math.cos(2 * math.pi * ((t / 4) % 1))
    pad = sum(voice(note * .5, t, .12) for note in notes[:3]) / 3
    pad *= (.11 + fade * .035) * warmth

    # Rounded bass and tiny confectionary percussion.
    bass_env = math.exp(-beat_position * 4.2)
    bass = voice(chord_root * .25, t, .08) * bass_env * .16
    shaker_phase = (t * 4) % 1
    deterministic_noise = math.sin(index * 12.9898 + len(track) * 78.233)
    shaker = deterministic_noise * math.exp(-shaker_phase * 18) * .025
    chime_env = math.exp(-beat_position * 9) if beat % 8 == 7 else 0
    chime = voice(notes[-1] * 2, t, .15) * chime_env * .08

    character = (sum(ord(char) for char in track) % 9 - 4) * .004
    left = pluck * .92 + pad + bass + shaker + chime * .45 + character
    right = pluck * .72 + pad * 1.04 + bass + shaker * .7 + chime + character
    master = .78
    return left * master, right * master


def write_track(name: str, notes: list[float], warmth: float) -> None:
    path = OUTPUT / f"{name}.wav"
    total = SAMPLE_RATE * DURATION
    frames = bytearray()
    for index in range(total):
        left, right = sample(name, notes, warmth, index)
        for value in (left, right):
            value = max(-1.0, min(1.0, value))
            frames.extend(int(value * 32767).to_bytes(2, "little", signed=True))
    with wave.open(str(path), "wb") as output:
        output.setnchannels(2)
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
