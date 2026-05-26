#!/usr/bin/env bash
set -euo pipefail

# Bonfire release build
# - Regenerates Xcode project
# - Builds Release config
# - Ad-hoc signs the .app
# - Zips it into dist/

cd "$(dirname "$0")/.."

OUT_DIR="dist"
APP_NAME="Bonfire.app"
BUNDLE_ID="ai.dotwise.Bonfire"

mkdir -p "$OUT_DIR"
rm -rf "$OUT_DIR/$APP_NAME" "$OUT_DIR/Bonfire.zip"

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

echo
echo "✓ Done: $OUT_DIR/$APP_NAME"
echo "✓ Zip:  $OUT_DIR/Bonfire.zip"
echo
echo "First-launch note: Gatekeeper will refuse to open an ad-hoc-signed app by"
echo "double-click. Right-click → Open → Open in the dialog, or run:"
echo "    xattr -dr com.apple.quarantine \"$OUT_DIR/$APP_NAME\""
