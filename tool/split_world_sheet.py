"""Split an AI-generated 3x2 world sheet into portrait runtime backgrounds."""

from __future__ import annotations

import argparse
from pathlib import Path

from PIL import Image


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("sheet", type=Path)
    parser.add_argument("output", type=Path)
    parser.add_argument("names", nargs=6)
    args = parser.parse_args()

    sheet = Image.open(args.sheet).convert("RGB")
    cell_width = sheet.width // 3
    cell_height = sheet.height // 2
    args.output.mkdir(parents=True, exist_ok=True)
    for index, name in enumerate(args.names):
        column = index % 3
        row = index // 3
        scene = sheet.crop(
            (
                column * cell_width + 2,
                row * cell_height + 2,
                (column + 1) * cell_width - 2,
                (row + 1) * cell_height - 2,
            )
        )
        scene.thumbnail((768, 1152), Image.Resampling.LANCZOS)
        scene.save(args.output / f"{name}.webp", "WEBP", quality=88, method=6)


if __name__ == "__main__":
    main()
