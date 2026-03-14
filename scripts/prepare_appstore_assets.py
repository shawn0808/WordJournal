#!/usr/bin/env python3
"""
Prepare Mac App Store screenshots and app preview.

Mac screenshot requirements (16:10 aspect ratio):
- 1280 x 800, 1440 x 900, 2560 x 1600, or 2880 x 1800

We output 1280x800 (can scale up in App Store Connect if needed).

Mac app preview (optional): 1920 x 1080, landscape, 15-30 sec, .mov/.m4v/.mp4
"""
import subprocess
import sys
from pathlib import Path
SCRIPT_DIR = Path(__file__).resolve().parent
PROJECT_ROOT = SCRIPT_DIR.parent
SCREENSHOTS_SRC = PROJECT_ROOT / "screenshots"
DOCS_SCREENSHOTS = PROJECT_ROOT / "docs" / "screenshots"
OUTPUT_DIR = PROJECT_ROOT / "AppStoreAssets"
TARGET_SIZE = (1280, 800)  # 16:10

# Preferred order for screenshots (best first)
PREFERRED_ORDER = [
    "definition-popup.png",
    "journal.png",
    "menu-bar.png",
    "preferences.png",
    "add-to-journal.png",
    "definition-popup-zoomed.png",
    "journal-zoomed.png",
    "menu-bar-zoomed.png",
    "preferences-zoomed.png",
    "add-to-journal-zoomed.png",
]


def collect_sources():
    """Gather available screenshots, preferring screenshots/ then docs/screenshots."""
    seen = set()
    result = []
    for name in PREFERRED_ORDER:
        for base in [SCREENSHOTS_SRC, DOCS_SCREENSHOTS]:
            p = base / name
            if p.exists() and p not in seen:
                seen.add(p)
                result.append((p, name))
                break
    # Add any remaining from screenshots/ or docs/screenshots
    for base in [SCREENSHOTS_SRC, DOCS_SCREENSHOTS]:
        if not base.exists():
            continue
        for f in sorted(base.glob("*.png")):
            if f not in seen and "icon" not in f.name.lower() and "og-" not in f.name.lower():
                seen.add(f)
                result.append((f, f.name))
    return result


def resize_with_sips(input_path: Path, output_path: Path, width: int, height: int) -> bool:
    """Use sips to resize to fit, then pad to exact dimensions."""
    try:
        # sips -Z fits longest dimension; then pad to target
        tmp = output_path.with_suffix(".tmp.png")
        subprocess.run(
            ["sips", "-Z", str(height), str(input_path), "--out", str(tmp)],
            check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL
        )
        subprocess.run(
            ["sips", "-z", str(height), str(width), "--padColor", "FFFFFF", str(tmp), "--out", str(output_path)],
            check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL
        )
        tmp.unlink(missing_ok=True)
        return True
    except (subprocess.CalledProcessError, FileNotFoundError):
        return False


def resize_with_pillow(input_path: Path, output_path: Path, width: int, height: int) -> bool:
    """Use Pillow for proper resize + pad to exact dimensions."""
    try:
        from PIL import Image
        img = Image.open(input_path).convert("RGB")
        # Resize to fit within target, maintaining aspect ratio
        resample = getattr(Image, "Resampling", Image).LANCZOS if hasattr(Image, "Resampling") else Image.LANCZOS
        img.thumbnail((width, height), resample)
        # Create new image with target size, white background
        out = Image.new("RGB", (width, height), (255, 255, 255))
        # Paste centered
        x = (width - img.width) // 2
        y = (height - img.height) // 2
        out.paste(img, (x, y))
        out.save(output_path, "PNG", optimize=True)
        return True
    except ImportError:
        return False
    except Exception as e:
        print(f"  Pillow error: {e}", file=sys.stderr)
        return False


def process_image(src_path: Path, out_path: Path) -> bool:
    if not resize_with_pillow(src_path, out_path, TARGET_SIZE[0], TARGET_SIZE[1]):
        return resize_with_sips(src_path, out_path, TARGET_SIZE[0], TARGET_SIZE[1])
    return True


def main():
    OUTPUT_DIR.mkdir(exist_ok=True)
    (OUTPUT_DIR / "screenshots").mkdir(exist_ok=True)

    print("Mac App Store assets - screenshots")
    print("=" * 40)
    print(f"Target size: {TARGET_SIZE[0]} x {TARGET_SIZE[1]} (16:10)")
    print()

    collected = collect_sources()
    # Duplicate from start if we have fewer than 10
    while len(collected) < 10 and collected:
        n = min(len(collected), 10 - len(collected))
        collected.extend(collected[:n])
    collected = collected[:10]

    for i, (src_path, name) in enumerate(collected, 1):
        out_name = f"screenshot-{i:02d}.png"
        out_path = OUTPUT_DIR / "screenshots" / out_name
        print(f"  {i}. {name} -> {out_name}")
        if process_image(src_path, out_path):
            print(f"     OK: {out_path}")
        else:
            print(f"     FAILED: {src_path}", file=sys.stderr)

    print()
    print(f"Done. Screenshots in: {OUTPUT_DIR / 'screenshots'}")
    print()

    # App preview (optional): 1920x1080, 15-30 sec
    preview_out = OUTPUT_DIR / "app-preview.mp4"
    demo = PROJECT_ROOT / "docs" / "demo_sped.mp4"
    if demo.exists():
        print("Mac App Store assets - app preview")
        print("=" * 40)
        print(f"Source: {demo}")
        print(f"Target: 1920x1080, max 30 sec")
        try:
            # Scale to 1920x1080 (pad if needed), trim to 30 sec
            subprocess.run(
                [
                    "ffmpeg", "-y",
                    "-i", str(demo),
                    "-t", "30",
                    "-vf", "scale=1920:1080:force_original_aspect_ratio=decrease,pad=1920:1080:(ow-iw)/2:(oh-ih)/2",
                    "-c:v", "libx264", "-preset", "medium", "-crf", "23",
                    "-c:a", "aac", "-b:a", "128k",
                    str(preview_out),
                ],
                check=True,
                stdout=subprocess.DEVNULL,
                stderr=subprocess.PIPE,
            )
            print(f"  OK: {preview_out}")
        except (subprocess.CalledProcessError, FileNotFoundError) as e:
            print("  ffmpeg not found or failed. Install: brew install ffmpeg")
            print(f"  Manual: ffmpeg -i docs/demo_sped.mp4 -t 30 -vf scale=1920:1080 -c:v libx264 app-preview.mp4")
    else:
        print("App preview: no docs/demo_sped.mp4 found")


if __name__ == "__main__":
    main()
