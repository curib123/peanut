"""Crop generated Phase 11 sprite sheets into consistent transparent assets."""

from __future__ import annotations

import argparse
from pathlib import Path

from PIL import Image


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("sheet", type=Path)
    parser.add_argument("output", type=Path)
    parser.add_argument("names", nargs="+")
    parser.add_argument("--columns", type=int, required=True)
    parser.add_argument("--rows", type=int, required=True)
    parser.add_argument("--size", type=int, default=384)
    args = parser.parse_args()

    if len(args.names) != args.columns * args.rows:
        raise ValueError("Name count must equal columns multiplied by rows.")

    sheet = Image.open(args.sheet).convert("RGBA")
    cell_width = sheet.width // args.columns
    cell_height = sheet.height // args.rows
    args.output.mkdir(parents=True, exist_ok=True)

    for index, name in enumerate(args.names):
        column = index % args.columns
        row = index // args.columns
        cell = sheet.crop(
            (
                column * cell_width,
                row * cell_height,
                (column + 1) * cell_width,
                (row + 1) * cell_height,
            )
        )
        alpha_box = cell.getchannel("A").getbbox()
        if alpha_box is None:
            raise ValueError(f"{name} contains no visible pixels.")
        subject = cell.crop(alpha_box)
        max_extent = int(args.size * 0.82)
        subject.thumbnail((max_extent, max_extent), Image.Resampling.LANCZOS)
        output = Image.new("RGBA", (args.size, args.size))
        output.alpha_composite(
            subject,
            ((args.size - subject.width) // 2, (args.size - subject.height) // 2),
        )
        output.save(args.output / f"{name}.png", optimize=True)


if __name__ == "__main__":
    main()
