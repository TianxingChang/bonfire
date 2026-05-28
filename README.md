# Bonfire

A macOS menu bar app that keeps your system awake on a timer — built for long coding sessions.

See `docs/superpowers/specs/2026-05-27-bonfire-design.md` for the design.

## Build

    brew install xcodegen
    xcodegen
    open Bonfire.xcodeproj

## Package

    ./scripts/build.sh

## Install

Run `./scripts/build.sh`. Two artifacts land in `dist/`:

- `Bonfire.dmg` — double-click, then drag Bonfire onto the Applications shortcut. Best for sharing.
- `Bonfire.zip` — unzip and move `Bonfire.app` to `/Applications` manually.

First launch: macOS will block ad-hoc-signed apps. Either:
- Right-click the app → Open → Open in the dialog, OR
- Run `xattr -dr com.apple.quarantine /Applications/Bonfire.app` once.
