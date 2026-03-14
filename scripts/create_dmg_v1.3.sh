#!/bin/bash
# Creates a pretty v1.3 DMG for Word Journal
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
OUTPUT_DMG="$PROJECT_DIR/docs/WordJournal-1.3.dmg"
BACKGROUND="$SCRIPT_DIR/dmg-background.png"

# Use full Xcode if available
if [ -d /Applications/Xcode.app ]; then
    export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
fi

echo "Building WordJournal Direct (Release)..."
cd "$PROJECT_DIR"
xcodebuild -scheme "WordJournal Direct" -configuration Release -derivedDataPath "$PROJECT_DIR/build" build 2>&1 | tail -5

APP_PATH="$PROJECT_DIR/build/Build/Products/Release/WordJournal.app"
if [ ! -d "$APP_PATH" ]; then
    echo "ERROR: Built app not found at $APP_PATH"
    exit 1
fi

# Create a folder for the DMG contents
DMG_SRC=$(mktemp -d)
cp -R "$APP_PATH" "$DMG_SRC/"

echo "Creating pretty DMG..."
create-dmg \
    --volname "Word Journal" \
    --background "$BACKGROUND" \
    --window-size 600 400 \
    --icon-size 100 \
    --icon "WordJournal.app" 150 180 \
    --app-drop-link 450 180 \
    --no-internet-enable \
    "$OUTPUT_DMG" \
    "$DMG_SRC"

rm -rf "$DMG_SRC"
echo "Done: $OUTPUT_DMG"
