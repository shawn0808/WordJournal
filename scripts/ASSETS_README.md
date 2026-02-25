# Creating website assets for Word Journal

Scripts and instructions for capturing screenshots, GIFs, and video for the landing page.

## Quick start

### 1. New screenshots (manual capture)

```bash
./scripts/capture_assets.sh
```

With the app open, position each window as prompted. Screenshots save to `screenshots/website/`. Review, crop if needed, then copy the best ones to `screenshots/` and rename with `-zoomed` suffix for the website (e.g. `definition-popup-zoomed.png`).

### 2. Create GIF from demo video

Requires [ffmpeg](https://ffmpeg.org/): `brew install ffmpeg`

```bash
./scripts/create_web_gif.sh
```

Creates `screenshots/demo-hero.gif` from the first 8 seconds of `demo-compressed.mp4`. Edit the script to change duration or size.

### 3. Optimize existing screenshots

```bash
./scripts/optimize_screenshots.sh
```

Resizes PNGs wider than 1200px for faster loading. Output goes to `screenshots/web-optimized/`.

## Recommended shots for the website

| Asset | Description | Notes |
|-------|-------------|-------|
| **Hero** | Demo video in docs/ | Autoplay, muted, loop — shows full workflow |
| **Definition popup** | Popup over selected text | Include pronunciation + add buttons |
| **Journal** | Main journal window | 3–5 entries, search bar visible |
| **Menu bar** | Dropdown open | Recent lookups + search field |
| **Add to journal GIF** | welcome-step4.gif | One-click add interaction |

## Current website assets

- **Hero**: `docs/demo.mp4` — full demo video (autoplay)
- **Screenshots**: `definition-popup-zoomed.png`, `journal-zoomed.png`, `menu-bar-zoomed.png`
- **GIF**: `welcome-step4.gif` — shown in "Stay in flow" feature card

All images are served from `screenshots/` via GitHub raw URLs for the live site.
