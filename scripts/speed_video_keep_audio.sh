#!/bin/bash
# Re-encode demo video: 20% faster video, original audio speed.
# Requires ffmpeg. Run from repo root: ./scripts/speed_video_keep_audio.sh

set -e
cd "$(dirname "$0")/.."
INPUT="docs/demo.mp4"
OUTPUT="docs/demo_sped.mp4"

if ! command -v ffmpeg &>/dev/null; then
  echo "ffmpeg not found. Install with: brew install ffmpeg"
  exit 1
fi

# Video 1.2x faster (setpts=PTS/1.2), audio unchanged. -shortest trims to video length.
ffmpeg -y -i "$INPUT" -filter:v "setpts=PTS/1.2" -c:a copy -movflags +faststart -shortest -f mp4 "${OUTPUT}.tmp"
mv "${OUTPUT}.tmp" "$OUTPUT"
echo "Created $OUTPUT. Update index.html to use demo_sped.mp4, or replace demo.mp4 with it."
