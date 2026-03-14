#!/usr/bin/env python3
"""
Fix macOS app icon size for dock display.
Per Apple HIG: artwork should be 832x832 (13/16 of 1024) centered in the canvas.
This prevents the icon from appearing oversized in the dock.
"""
import os
from PIL import Image

ICON_DIR = os.path.join(os.path.dirname(__file__), "..", "WordJournal", "Resources", "Assets.xcassets", "AppIcon.appiconset")
# Use 75% to match dock size of other apps (13/16 ≈ 81% can still appear large)
SAFE_RATIO = 0.75

SIZES = [16, 32, 64, 128, 256, 512, 1024]

def fix_icon(path: str, size: int) -> None:
    """Add proper padding so artwork is 13/16 of canvas, centered."""
    img = Image.open(path).convert("RGBA")
    w, h = img.size

    # Target size for the artwork
    art_size = int(size * SAFE_RATIO)
    # Resize artwork to fit safe area
    art = img.resize((art_size, art_size), Image.LANCZOS)

    # Create new canvas (preserve transparency)
    canvas = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    # Center the artwork
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
