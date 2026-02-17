#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

BUILD_PATH=".build-local"
PRODUCT="MacWiFi"
BIN="$BUILD_PATH/debug/$PRODUCT"
APP_BUNDLE="$PRODUCT.app"

printf "\n▶️  Building $PRODUCT (debug, build path: $BUILD_PATH)\n"
swift build -c debug --product "$PRODUCT" --build-path "$BUILD_PATH"

printf "\n📦 Updating app bundle...\n"
# Create bundle structure only if it doesn't exist (preserves permissions)
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"

# Update binary and plist
cp "$BIN" "$APP_BUNDLE/Contents/MacOS/$PRODUCT"
cp "Sources/$PRODUCT/Info.plist" "$APP_BUNDLE/Contents/Info.plist"

# Skip codesigning to preserve location permission

printf "\n⏹  Stopping existing $PRODUCT...\n"
killall -q "$PRODUCT" 2>/dev/null || true
sleep 0.5

printf "\n🚀 Launching $APP_BUNDLE ...\n"
open "$APP_BUNDLE"
printf "Started $PRODUCT from $APP_BUNDLE\n"
