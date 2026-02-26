#!/usr/bin/env python3
"""
Second-pass post-processing for Recraft SVG icons.
Fixes near-black fills, duplicate xmlns, and background removal.
"""

import os
import re
import glob

ITEM_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "docs", "art", "icon-experiments", "method-b", "item-icons")
HUD_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "docs", "art", "icon-experiments", "method-b", "hud-icons")


def fix_svg(filepath: str) -> None:
    with open(filepath, "r", encoding="utf-8") as f:
        svg = f.read()

    # Fix duplicate xmlns — remove all xmlns, then ensure exactly one
    svg = re.sub(r'\s*xmlns="http://www\.w3\.org/2000/svg"', '', svg)
    svg = svg.replace('<svg ', '<svg xmlns="http://www.w3.org/2000/svg" ', 1)

    # Convert ALL rgb() fills to currentColor (style guide requires currentColor only)
    svg = re.sub(r'fill="rgb\(\d+,\s*\d+,\s*\d+\)"', 'fill="currentColor"', svg)

    # Remove background: first path in the <g> that covers the full canvas
    svg = re.sub(
        r'<path d="M 0 0 L 2048 0 L 2048 2048 L 0 2048[^"]*" fill="[^"]*"\s*/?>',
        '',
        svg
    )
    svg = re.sub(
        r'<path d="M 0 0 L 2048 0 L 2048 2048 L 0 204[^"]*" fill="currentColor"\s*/?>',
        '',
        svg
    )

    with open(filepath, "w", encoding="utf-8") as f:
        f.write(svg)


def main():
    count = 0
    for directory in [ITEM_DIR, HUD_DIR]:
        for filepath in glob.glob(os.path.join(directory, "*.svg")):
            fix_svg(filepath)
            count += 1
            print(f"Fixed: {os.path.basename(filepath)}")
    print(f"\nProcessed {count} files")


if __name__ == "__main__":
    main()
