#!/usr/bin/env python3
"""
Restore app icon to full size for dock display.
Reverses the padding from fix_app_icon_size.py - crops the center artwork
and scales it to fill the canvas so the dock icon matches other apps.
"""
import os
from PIL import Image

ICON_DIR = os.path.join(os.path.dirname(__file__), "..", "WordJournal", "Resources", "Assets.xcassets", "AppIcon.appiconset")

# Current icons have artwork at 75% (from fix script). We crop that center and scale to 100%.
CURRENT_ART_RATIO = 0.75

SIZES = [16, 32, 64, 128, 256, 512, 1024]


def restore_icon(path: str, size: int) -> None:
    """Crop center artwork and scale to fill canvas."""
    img = Image.open(path).convert("RGBA")
    w, h = img.size

    # Crop to center artwork (the 75% region)
    crop_size = int(size * CURRENT_ART_RATIO)
    left = (size - crop_size) // 2
    top = (size - crop_size) // 2
    cropped = img.crop((left, top, left + crop_size, top + crop_size))

    # Scale cropped artwork to full size
    fullsize = cropped.resize((size, size), Image.LANCZOS)
    fullsize.save(path)


def main():
    for s in SIZES:
        fname = f"icon_{s}.png"
        path = os.path.join(ICON_DIR, fname)
        if os.path.exists(path):
            restore_icon(path, s)
            print(f"Restored {fname}")
        else:
            print(f"Skip {fname} (not found)")


if __name__ == "__main__":
    main()
