"""Check the original SFX export contract and basic playback safety."""

from __future__ import annotations

import contextlib
import hashlib
import io
import math
import struct
import tempfile
import unittest
import wave
from pathlib import Path
from unittest.mock import patch

import generate_sfx


EXPECTED = {
    "blocker_hit.wav", "button.wav", "cascade.wav", "fall.wav",
    "golden_spark.wav", "invalid.wav", "land.wav", "lose.wav", "match.wav",
    "oven_burst.wav", "peanut_kisses.wav", "peanut_spinner.wav", "select.wav",
    "shuffle.wav", "special.wav", "special_create.wav", "sugar_beam.wav",
    "swap.wav", "win.wav",
}
ASSETS = Path(__file__).resolve().parents[1] / "assets/audio/sfx"


class SoundExportTest(unittest.TestCase):
    def test_packaged_cues_are_bounded_click_free_stereo_pcm(self) -> None:
        files = list(ASSETS.glob("*.wav"))
        self.assertEqual({path.name for path in files}, EXPECTED)
        self.assertLess(sum(path.stat().st_size for path in files), 1_800_000)
        for path in files:
            with self.subTest(cue=path.name), wave.open(str(path), "rb") as sound:
                self.assertEqual(sound.getnchannels(), 2)
                self.assertEqual(sound.getsampwidth(), 2)
                self.assertEqual(sound.getframerate(), 44_100)
                duration = sound.getnframes() / sound.getframerate()
                self.assertGreaterEqual(duration, 0.07)
                self.assertLessEqual(duration, 1.25)
                data = sound.readframes(sound.getnframes())
                samples = [value / 32768 for (value,) in struct.iter_unpack("<h", data)]
                peak = max(abs(value) for value in samples)
                rms = math.sqrt(sum(value * value for value in samples) / len(samples))
                self.assertGreater(peak, 0.12)
                self.assertLessEqual(peak, 0.68, "leave headroom for overlapping cues")
                self.assertGreater(rms, 0.015)
                self.assertLess(rms, 0.22)
                for channel in (samples[::2], samples[1::2]):
                    self.assertTrue(all(value == 0 for value in channel[:88]))
                    self.assertTrue(all(value == 0 for value in channel[-88:]))
                    self.assertLess(abs(sum(channel) / len(channel)), 0.003)
                    step = max(abs(b - a) for a, b in zip(channel, channel[1:]))
                    self.assertLess(step, 0.28, "avoid discontinuities at layer joins")
                self.assertTrue(any(a != b for a, b in zip(samples[::2], samples[1::2])))

    def test_regeneration_is_identical_and_keeps_the_existing_manifest(self) -> None:
        with tempfile.TemporaryDirectory() as folder:
            output = Path(folder)
            with patch.object(generate_sfx, "OUT", output), contextlib.redirect_stdout(io.StringIO()):
                generate_sfx.main()
                first = {
                    path.name: hashlib.sha256(path.read_bytes()).hexdigest()
                    for path in output.glob("*.wav")
                }
                generate_sfx.main()
                second = {
                    path.name: hashlib.sha256(path.read_bytes()).hexdigest()
                    for path in output.glob("*.wav")
                }
            self.assertEqual(set(first), EXPECTED)
            self.assertEqual(first, second)
            self.assertEqual(first, {
                path.name: hashlib.sha256(path.read_bytes()).hexdigest()
                for path in ASSETS.glob("*.wav")
            }, "packaged cues must match the checked-in generator")


if __name__ == "__main__":
    unittest.main(verbosity=2)
