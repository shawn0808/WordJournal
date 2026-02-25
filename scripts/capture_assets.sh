#!/bin/bash
# Capture screenshots and prepare assets for the Word Journal website
# Run this with the Word Journal app open in the states described below.

set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
SCREENSHOTS="$PROJECT_ROOT/screenshots"
OUTPUT="$SCREENSHOTS/website"

mkdir -p "$OUTPUT"

echo "Word Journal — Asset capture"
echo "============================"
echo ""
echo "This script will capture screenshots. Have Word Journal ready in these states:"
echo ""
echo "  1. Definition popup — Select a word in any app, Shift+Click to show definition"
echo "  2. Journal window — Open Journal (⌘J) with some entries"
echo "  3. Menu bar — Click the menu bar icon to show dropdown"
echo "  4. Add to journal — Popup visible with a word, hover over + button"
echo ""
echo "Press Enter to start, or Ctrl+C to cancel..."
read

# Helper: capture after delay so you can position
capture() {
  local name="$1"
  local delay="${2:-3}"
  echo "Capturing $name in ${delay}s — position the window now!"
  sleep "$delay"
  screencapture -i -o "$OUTPUT/${name}.png"
  echo "  ✓ Saved $OUTPUT/${name}.png"
}

# Full screen capture (no -i)
capture_full() {
  local name="$1"
  local delay="${2:-2}"
  echo "Capturing entire screen for $name in ${delay}s..."
  sleep "$delay"
  screencapture -o "$OUTPUT/${name}.png"
  echo "  ✓ Saved $OUTPUT/${name}.png"
}

echo ""
echo "=== 1. Definition popup ==="
echo "Select a word (e.g. in Safari or Notes), Shift+Click to show the popup."
capture "definition-popup" 5

echo ""
echo "=== 2. Journal window ==="
echo "Open the Journal (⌘J). Make sure it has a few entries and the search bar is visible."
capture "journal" 5

echo ""
echo "=== 3. Menu bar dropdown ==="
echo "Click the Word Journal icon in the menu bar to open the dropdown."
capture "menu-bar" 5

echo ""
echo "=== 4. Add to journal (optional) ==="
echo "Show the definition popup with the word. Hover over a + button if possible."
capture "add-to-journal" 5

echo ""
echo "Done! Screenshots saved to: $OUTPUT"
echo ""
echo "Next steps:"
echo "  1. Crop/size images as needed (Preview or script)"
echo "  2. Run: ./scripts/create_web_gif.sh  (requires ffmpeg: brew install ffmpeg)"
echo "  3. Copy best assets to screenshots/ and push to GitHub"
