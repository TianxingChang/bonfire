#!/usr/bin/env bash
set -euo pipefail

# Bonfire release build
# - Regenerates Xcode project
# - Builds Release config
# - Ad-hoc signs the .app
# - Produces dist/Bonfire.zip AND dist/Bonfire.dmg (drag-to-Applications)

cd "$(dirname "$0")/.."

OUT_DIR="dist"
APP_NAME="Bonfire.app"
BUNDLE_ID="ai.dotwise.Bonfire"
DMG_NAME="Bonfire.dmg"
VOL_NAME="Bonfire"

mkdir -p "$OUT_DIR"
rm -rf "$OUT_DIR/$APP_NAME" "$OUT_DIR/Bonfire.zip" "$OUT_DIR/$DMG_NAME"

echo "→ Regenerating project"
xcodegen

echo "→ Building Release"
DERIVED="$(mktemp -d)"
xcodebuild \
    -project Bonfire.xcodeproj \
    -scheme Bonfire \
    -configuration Release \
    -derivedDataPath "$DERIVED" \
    CODE_SIGN_IDENTITY="-" \
    CODE_SIGNING_REQUIRED=YES \
    CODE_SIGNING_ALLOWED=YES \
    build

BUILT_APP="$DERIVED/Build/Products/Release/$APP_NAME"
if [ ! -d "$BUILT_APP" ]; then
    echo "Build did not produce $BUILT_APP" >&2
    exit 1
fi

echo "→ Copying to $OUT_DIR/"
cp -R "$BUILT_APP" "$OUT_DIR/"

echo "→ Verifying ad-hoc signature"
codesign --verify --verbose "$OUT_DIR/$APP_NAME"

echo "→ Zipping"
( cd "$OUT_DIR" && zip -ry Bonfire.zip "$APP_NAME" >/dev/null )

echo "→ Building DMG"
STAGE_DIR="$(mktemp -d)/Bonfire"
mkdir -p "$STAGE_DIR"
cp -R "$OUT_DIR/$APP_NAME" "$STAGE_DIR/"
ln -s /Applications "$STAGE_DIR/Applications"  # so user can drag→install in one motion
hdiutil create \
    -volname "$VOL_NAME" \
    -srcfolder "$STAGE_DIR" \
    -ov \
    -format UDZO \
    "$OUT_DIR/$DMG_NAME" >/dev/null
rm -rf "$(dirname "$STAGE_DIR")"

echo
echo "✓ Done: $OUT_DIR/$APP_NAME"
echo "✓ Zip:  $OUT_DIR/Bonfire.zip"
echo "✓ DMG:  $OUT_DIR/$DMG_NAME    ← share this with friends"
echo
echo "First-launch note for recipients: Gatekeeper will refuse to open an"
echo "ad-hoc-signed app by double-click. They should right-click → Open →"
echo "Open in the dialog, or run:"
echo "    xattr -dr com.apple.quarantine /Applications/Bonfire.app"
