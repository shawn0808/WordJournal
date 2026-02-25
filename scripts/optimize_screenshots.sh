#!/bin/bash
# Optimize existing screenshots for web (resize, optional compression)
# Uses macOS built-in sips — no extra installs needed

set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
SCREENSHOTS="$PROJECT_ROOT/screenshots"
OUTPUT="$PROJECT_ROOT/screenshots/web-optimized"
MAX_WIDTH=1200  # Good for 2x retina on most screens

mkdir -p "$OUTPUT"

echo "Optimizing screenshots for web (max width: ${MAX_WIDTH}px)..."
echo ""

for img in "$SCREENSHOTS"/*.png; do
  [[ -f "$img" ]] || continue
  name=$(basename "$img" .png)
  out="$OUTPUT/${name}.png"
  
  # Resize if wider than max, preserve aspect ratio
  w=$(sips -g pixelWidth "$img" 2>/dev/null | awk '/pixelWidth/{print $2}')
  if [[ -n "$w" ]] && [[ "$w" -gt "$MAX_WIDTH" ]]; then
    sips -Z "$MAX_WIDTH" "$img" --out "$out" 2>/dev/null
    echo "  Resized: $name ($w → ${MAX_WIDTH}px)"
  else
    cp "$img" "$out"
    echo "  Copied:  $name (no resize needed)"
  fi
done

echo ""
echo "Optimized images saved to: $OUTPUT"
echo "Review and replace screenshots/ with these if desired, or use web-optimized/ for the site."
