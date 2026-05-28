#!/usr/bin/env bash
set -euo pipefail

# Regenerates Bonfire/AppIcon.icns from a 1024×1024 source PNG.
# We use the *original* burning.png (before the menu-bar centering crop),
# pulled from the commit where it was first added.
#
# Usage: ./scripts/make-icon.sh [path/to/source-1024.png]

cd "$(dirname "$0")/.."

SRC="${1:-}"
if [ -z "$SRC" ]; then
    # Default: pull from git history — commit 3a12ee4 has the 1024×1024 source
    SRC="$(mktemp -t bonfire-icon-src.XXXXXX.png)"
    git show 3a12ee4:Bonfire/Resources/burning.png > "$SRC"
    echo "→ Using burning.png from commit 3a12ee4 (1024×1024 original)"
fi

ICONSET="$(mktemp -d)/AppIcon.iconset"
mkdir -p "$ICONSET"

echo "→ Rendering size variants"
sips -z 16   16   "$SRC" --out "$ICONSET/icon_16x16.png"      >/dev/null
sips -z 32   32   "$SRC" --out "$ICONSET/icon_16x16@2x.png"   >/dev/null
sips -z 32   32   "$SRC" --out "$ICONSET/icon_32x32.png"      >/dev/null
sips -z 64   64   "$SRC" --out "$ICONSET/icon_32x32@2x.png"   >/dev/null
sips -z 128  128  "$SRC" --out "$ICONSET/icon_128x128.png"    >/dev/null
sips -z 256  256  "$SRC" --out "$ICONSET/icon_128x128@2x.png" >/dev/null
sips -z 256  256  "$SRC" --out "$ICONSET/icon_256x256.png"    >/dev/null
sips -z 512  512  "$SRC" --out "$ICONSET/icon_256x256@2x.png" >/dev/null
sips -z 512  512  "$SRC" --out "$ICONSET/icon_512x512.png"    >/dev/null
cp "$SRC" "$ICONSET/icon_512x512@2x.png"

echo "→ Packaging .icns"
iconutil -c icns "$ICONSET" -o Bonfire/AppIcon.icns
rm -rf "$(dirname "$ICONSET")"

echo
echo "✓ Wrote Bonfire/AppIcon.icns ($(du -h Bonfire/AppIcon.icns | cut -f1))"
