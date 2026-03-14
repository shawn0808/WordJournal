#!/usr/bin/env python3
"""
Fix macOS app icon to proper dock size per Apple HIG.
- Scales artwork to ~80% of canvas (Apple grid: 824/1024)
- Uses the icon's own blue border color as full-canvas background
- macOS clips to squircle automatically, giving visible rounded corners
"""
import os
from PIL import Image, ImageDraw
import numpy as np

ICON_DIR = os.path.join(os.path.dirname(__file__), "..", "WordJournal", "Resources", "Assets.xcassets", "AppIcon.appiconset")

SAFE_RATIO = 0.80
BG_COLOR = (91, 129, 168, 255)

SIZES = [16, 32, 64, 128, 256, 512, 1024]


def fix_icon(path: str, size: int) -> None:
    img = Image.open(path).convert("RGBA")
    arr = np.array(img)

    art_size = int(size * SAFE_RATIO)

    art = img.resize((art_size, art_size), Image.LANCZOS)

    canvas = Image.new("RGBA", (size, size), BG_COLOR)

    x = (size - art_size) // 2
    y = (size - art_size) // 2
    canvas.paste(art, (x, y), art)

    canvas.save(path)


def main():
    for s in SIZES:
        fname = f"icon_{s}.png"
        path = os.path.join(ICON_DIR, fname)
        if os.path.exists(path):
            fix_icon(path, s)
            print(f"Fixed {fname}")
        else:
            print(f"Skip {fname} (not found)")


if __name__ == "__main__":
    main()
