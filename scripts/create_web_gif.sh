#!/bin/bash
# Create web-optimized GIF from demo video using ffmpeg
# Install ffmpeg: brew install ffmpeg

set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
VIDEO="$PROJECT_ROOT/demo-compressed.mp4"
OUTPUT="$PROJECT_ROOT/screenshots/demo-hero.gif"

if ! command -v ffmpeg &>/dev/null; then
  echo "ffmpeg is required. Install with: brew install ffmpeg"
  exit 1
fi

if [[ ! -f "$VIDEO" ]]; then
  echo "Video not found: $VIDEO"
  exit 1
fi

echo "Creating GIF from demo video..."
echo "Input:  $VIDEO"
echo "Output: $OUTPUT"
echo ""

# Get video duration to trim if needed (e.g. first 8 seconds)
# Scale to 800px width, 15 fps for smaller file, palette for better colors
ffmpeg -y -i "$VIDEO" \
  -vf "fps=12,scale=800:-1:flags=lanczos,split[s0][s1];[s0]palettegen=max_colors=128[p];[s1][p]paletteuse=dither=bayer" \
  -t 8 \
  -loop 0 \
  "$OUTPUT" 2>/dev/null

echo "✓ Created $OUTPUT"
echo ""
echo "For a shorter clip (first 4 seconds), run:"
echo "  ffmpeg -y -i $VIDEO -vf 'fps=12,scale=800:-1:flags=lanczos,split[s0][s1];[s0]palettegen[p];[s1][p]paletteuse' -t 4 -loop 0 screenshots/demo-short.gif"
