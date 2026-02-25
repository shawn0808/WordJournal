#!/bin/bash
# Creates a signed and notarized DMG for Word Journal (set VERSION env to override)
# Requires: Developer ID Application certificate, create-dmg (brew install create-dmg)
# Prerequisites for notarization:
#   1. App-specific password: https://appleid.apple.com → Sign-In and Security → App-Specific Passwords
#   2. Store in keychain: xcrun notarytool store-credentials AC_PASSWORD --apple-id "YOUR_APPLE_ID" --team-id "YOUR_TEAM_ID" --password "app-specific-password"
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
BUILD_DIR="$PROJECT_DIR/build"
VERSION="${VERSION:-1.4}"
OUTPUT_DMG="$PROJECT_DIR/docs/WordJournal-${VERSION}.dmg"
BACKGROUND="$SCRIPT_DIR/dmg-background.png"

# Signing identity - use full "Developer ID Application: Name (TEAM)" for distribution
# Find yours with: security find-identity -v -p codesigning
if [ -z "$SIGNING_IDENTITY" ]; then
    SIGNING_IDENTITY=$(security find-identity -v -p codesigning 2>/dev/null | grep "Developer ID Application:" | head -1 | sed 's/.*"\([^"]*\)".*/\1/')
    [ -z "$SIGNING_IDENTITY" ] && SIGNING_IDENTITY="Developer ID Application"
fi

# Notarization - uses stored credentials from 'notarytool store-credentials AC_PASSWORD'
# Or set: NOTARY_APPLE_ID, NOTARY_TEAM_ID, NOTARY_PASSWORD
NOTARY_PROFILE="${NOTARY_PROFILE:-AC_PASSWORD}"

# Use full Xcode if available
if [ -d /Applications/Xcode.app ]; then
    export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
fi

# Check for Developer ID certificate (required for distribution)
if ! security find-identity -v -p codesigning 2>/dev/null | grep -q "Developer ID Application"; then
    echo "ERROR: No 'Developer ID Application' certificate found."
    echo ""
    echo "Required for signed/notarized distribution. Get it from:"
    echo "  https://developer.apple.com/account/resources/certificates/list"
    echo "  → Click + → Developer ID Application"
    echo ""
    echo "Your current identities:"
    security find-identity -v -p codesigning 2>/dev/null || true
    exit 1
fi

# Check for create-dmg
if ! command -v create-dmg &>/dev/null; then
    echo "ERROR: create-dmg not found. Install with: brew install create-dmg"
    exit 1
fi

echo "=== Building WordJournal (Release) ==="
cd "$PROJECT_DIR"
xcodebuild -scheme WordJournal -configuration Release \
    -derivedDataPath "$BUILD_DIR" \
    build 2>&1 | tail -20

APP_PATH="$BUILD_DIR/Build/Products/Release/WordJournal.app"
if [ ! -d "$APP_PATH" ]; then
    echo "ERROR: Built app not found at $APP_PATH"
    exit 1
fi

echo ""
echo "=== Re-signing app with Developer ID: $SIGNING_IDENTITY ==="
# Sign in correct order (do NOT use --deep - it corrupts Sparkle XPC services)
# All components need --timestamp and hardened runtime for notarization
# Sign innermost binaries first, then bundles
SPARKLE_FRAMEWORK="$APP_PATH/Contents/Frameworks/Sparkle.framework"
if [ -d "$SPARKLE_FRAMEWORK" ]; then
    SPARKLE_B="$SPARKLE_FRAMEWORK/Versions/B"
    # 1. XPC services
    if [ -d "$SPARKLE_B/XPCServices/Installer.xpc" ]; then
        codesign -f -s "$SIGNING_IDENTITY" -o runtime --timestamp \
            "$SPARKLE_B/XPCServices/Installer.xpc"
    fi
    if [ -d "$SPARKLE_B/XPCServices/Downloader.xpc" ]; then
        codesign -f -s "$SIGNING_IDENTITY" -o runtime --preserve-metadata=entitlements --timestamp \
            "$SPARKLE_B/XPCServices/Downloader.xpc"
    fi
    # 2. Updater.app - sign inner executable first, then the .app bundle
    UPDATER_APP="$SPARKLE_B/Updater.app"
    if [ -d "$UPDATER_APP" ]; then
        UPDATER_BIN="$UPDATER_APP/Contents/MacOS/Updater"
        if [ -f "$UPDATER_BIN" ]; then
            codesign -f -s "$SIGNING_IDENTITY" -o runtime --timestamp "$UPDATER_BIN"
        fi
        codesign -f -s "$SIGNING_IDENTITY" -o runtime --timestamp "$UPDATER_APP"
    fi
    # 3. Autoupdate (standalone binary)
    if [ -f "$SPARKLE_B/Autoupdate" ]; then
        codesign -f -s "$SIGNING_IDENTITY" -o runtime --timestamp "$SPARKLE_B/Autoupdate"
    fi
    # 4. Sparkle framework
    codesign -f -s "$SIGNING_IDENTITY" -o runtime --timestamp "$SPARKLE_FRAMEWORK"
fi
# Sign main app (with entitlements)
ENTITLEMENTS="$PROJECT_DIR/WordJournal/WordJournal.entitlements"
if [ -f "$ENTITLEMENTS" ]; then
    codesign -f -s "$SIGNING_IDENTITY" --timestamp --options runtime \
        --entitlements "$ENTITLEMENTS" "$APP_PATH"
else
    codesign -f -s "$SIGNING_IDENTITY" --timestamp --options runtime "$APP_PATH"
fi

echo ""
echo "=== Verifying Sparkle components have Developer ID + timestamp ==="
if [ -d "$SPARKLE_FRAMEWORK" ]; then
    for comp in "$SPARKLE_B/Updater.app" "$SPARKLE_B/Autoupdate"; do
        if [ -e "$comp" ]; then
            echo "  $comp"
            codesign -dv "$comp" 2>&1 | grep -E "Authority|Timestamp" || true
        fi
    done
fi
echo ""
echo "=== Verifying main app signature ==="
codesign -dv --verbose=2 "$APP_PATH" 2>&1 | head -5 || true

echo ""
echo "=== Creating DMG ==="
DMG_SRC=$(mktemp -d)
cp -R "$APP_PATH" "$DMG_SRC/"

# Remove existing DMG so create-dmg doesn't complain
rm -f "$OUTPUT_DMG"

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

echo ""
echo "=== Signing DMG ==="
codesign --force --sign "$SIGNING_IDENTITY" --timestamp \
    "$OUTPUT_DMG"

echo ""
echo "=== Submitting for notarization ==="
NOTARIZE_OK=0
if [ -n "$NOTARY_APPLE_ID" ] && [ -n "$NOTARY_TEAM_ID" ] && [ -n "$NOTARY_PASSWORD" ]; then
    xcrun notarytool submit "$OUTPUT_DMG" \
        --apple-id "$NOTARY_APPLE_ID" \
        --team-id "$NOTARY_TEAM_ID" \
        --password "$NOTARY_PASSWORD" \
        --wait && NOTARIZE_OK=1 || true
else
    xcrun notarytool submit "$OUTPUT_DMG" \
        --keychain-profile "$NOTARY_PROFILE" \
        --wait && NOTARIZE_OK=1 || true
fi

if [ "$NOTARIZE_OK" -eq 1 ]; then
    echo ""
    echo "=== Stapling notarization ticket ==="
    xcrun stapler staple "$OUTPUT_DMG"
    echo ""
    echo "=== Done ==="
    echo "DMG (signed + notarized): $OUTPUT_DMG"
else
    echo ""
    echo "Notarization skipped or failed. DMG is signed but not notarized."
    echo "To notarize manually:"
    echo "  1. Store credentials: xcrun notarytool store-credentials $NOTARY_PROFILE --apple-id YOUR_EMAIL --team-id YOUR_TEAM_ID --password 'app-specific-password'"
    echo "  2. Submit: xcrun notarytool submit $OUTPUT_DMG --keychain-profile $NOTARY_PROFILE --wait"
    echo "  3. Staple: xcrun stapler staple $OUTPUT_DMG"
    echo ""
    echo "Signed DMG: $OUTPUT_DMG"
fi
