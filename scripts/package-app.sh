#!/usr/bin/env bash
set -euo pipefail

# Builds a distributable phacius_vnkey.dmg. End users just drag the .app to
# /Applications — no Rust, no toolchain. Rust is only needed HERE (build time);
# the engine is statically linked into the executable.

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MACOS_DIR="$REPO_ROOT/apps/macos"
DIST="$REPO_ROOT/dist"
APP="$DIST/phacius_vnkey.app"
VERSION="$(/usr/libexec/PlistBuddy -c 'Print CFBundleShortVersionString' "$MACOS_DIR/Info.plist")"

echo "==> Building Rust engine + header..."
bash "$REPO_ROOT/scripts/build-engine.sh"

echo "==> Building Swift app (release)..."
swift build --package-path "$MACOS_DIR" -c release

echo "==> Assembling .app bundle..."
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$MACOS_DIR/.build/release/VnkeyApp" "$APP/Contents/MacOS/VnkeyApp"
cp "$MACOS_DIR/Info.plist" "$APP/Contents/Info.plist"

# Ad-hoc sign so the bundle keeps a stable identity across launches —
# required for Accessibility permission to persist. Replace "-" with your
# Developer ID to ship notarized.
echo "==> Ad-hoc code signing..."
codesign --force --deep --sign - "$APP"

echo "==> Building .dmg..."
DMG="$DIST/phacius_vnkey-$VERSION.dmg"
rm -f "$DMG"
STAGE="$(mktemp -d)"
cp -R "$APP" "$STAGE/"
ln -s /Applications "$STAGE/Applications"
hdiutil create -volname "phacius_vnkey" -srcfolder "$STAGE" -ov -format UDZO "$DMG" >/dev/null
rm -rf "$STAGE"

echo "==> Done: $DMG"
