#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

APP_NAME="Duoob"
VERSION="$(grep '^version:' pubspec.yaml | awk '{print $2}' | cut -d'+' -f1)"
APP_PATH="build/macos/Build/Products/Release/${APP_NAME}.app"
STAGING_DIR="build/macos/dmg-staging"
DMG_PATH="build/macos/${APP_NAME}-${VERSION}-macos.dmg"

echo "Building release app..."
flutter build macos --release

if [[ ! -d "$APP_PATH" ]]; then
  echo "Error: App bundle not found at $APP_PATH"
  exit 1
fi

echo "Creating DMG..."
rm -rf "$STAGING_DIR"
mkdir -p "$STAGING_DIR"
cp -R "$APP_PATH" "$STAGING_DIR/"
ln -sf /Applications "$STAGING_DIR/Applications"
rm -f "$DMG_PATH"

hdiutil create \
  -volname "$APP_NAME" \
  -srcfolder "$STAGING_DIR" \
  -ov \
  -format UDZO \
  "$DMG_PATH"

rm -rf "$STAGING_DIR"

echo ""
echo "DMG created: $DMG_PATH"
echo "Open it, drag Duoob to Applications, then launch from Applications."
