<div align="right">

**English** · [简体中文](./README.zh.md)

</div>

<div align="center">
  <img src="Bonfire/Resources/burning.png" width="120" alt="Bonfire icon">

# Bonfire

**A tiny macOS menu bar app that keeps your Mac awake — even with the lid closed.**

Built for long unattended runs: agent loops, builds, model training, big downloads.

</div>

---

## Features

- 🔥 **Menu bar toggle** — click a preset (30m / 1h / 2h / 4h), custom duration, or forever
- 🌙 **Turn off display while keeping awake** — press the lid-close button and walk away
- 🔌 **Lid-close-aware** — when plugged in, your Mac stays awake with the lid shut
- 🔋 **Battery mode** — opt-in *advanced* override (`pmset disablesleep`) lets the lid-closed-awake trick work on battery too
- 🛡️ **Battery safety rail** — auto-stops at a low-battery threshold (default 20%) so an unattended run can't drain your battery to zero
- 🔐 **One password prompt, ever** — the advanced mode installs a tiny `sudoers` fragment so subsequent uses are silent
- ⏱️ **Smart timer** — "Until 23:00" picks the *next* occurrence; if it already passed today, rolls to tomorrow
- 💤 **Graceful exit** — auto-restores normal sleep policy when the timer expires, you stop manually, or the app crashes

## Install

Grab the latest `Bonfire.dmg` from [Releases](../../releases) → double-click → drag Bonfire onto the Applications shortcut.

**First launch**: macOS Gatekeeper blocks ad-hoc-signed apps. Either:

- **Right-click the app → Open → Open** in the dialog that appears, or
- Run once:
  ```bash
  xattr -dr com.apple.quarantine /Applications/Bonfire.app
  ```

That's a one-time step. After the first launch macOS remembers.

## How it works

Two layers of awake-keeping that stack:

| Layer | API | Effect | Privileges |
|---|---|---|---|
| Idle / system sleep | `IOPMAssertion` (`PreventUserIdleSystemSleep` + `PreventSystemSleep`) | Stops the system from idle-sleeping. On AC power this is enough to keep a closed lid awake. | None |
| Forced lid-close sleep on battery | `pmset -b disablesleep 1` via passwordless `sudo` | Overrides macOS's hardware-level "lid closed on battery → sleep" policy. | Admin (one-time install) |

Display dimming uses `pmset displaysleepnow` (no admin required).

Full design rationale and trade-offs: [`docs/design.md`](docs/design.md).

## Building from source

Requires Xcode 15+ and Homebrew.

```bash
brew install xcodegen
git clone https://github.com/<your-user>/bonfire.git
cd bonfire
xcodegen
open Bonfire.xcodeproj
```

Or for a distributable build:

```bash
./scripts/build.sh
# → dist/Bonfire.app, dist/Bonfire.zip, dist/Bonfire.dmg
```

Run the full test suite:

```bash
xcodebuild -project Bonfire.xcodeproj -scheme Bonfire -destination 'platform=macOS' test
```

49 unit tests covering the state machine, timer math, preferences persistence, and IOKit wrappers.

## Project layout

```
Bonfire/
├── BonfireApp.swift                @main entry
├── AppIcon.icns                    App icon (regenerate via scripts/make-icon.sh)
├── Core/
│   ├── BonfireDomain.swift         State enums
│   ├── BonfireController.swift     State machine (testable, mocked deps)
│   ├── AssertionManager.swift      IOPMAssertion wrapper
│   ├── PowerMonitor.swift          IOPS power source events
│   ├── Notifier.swift              UserNotifications wrapper
│   ├── BatteryAwakeBypass.swift    pmset + sudoers fragment installer
│   └── DurationCalculator.swift    "Until" rollover math
├── Support/
│   ├── Preferences.swift           @AppStorage-backed config
│   ├── LaunchAtLogin.swift         SMAppService wrapper
│   ├── IconRenderer.swift          Menu bar icon (PNG + fallback)
│   ├── Display.swift               pmset displaysleepnow
│   └── WindowAccessor.swift        SwiftUI ↔ NSWindow bridge
├── Views/
│   ├── PopoverView.swift           State router (idle vs burning)
│   ├── IdleLayout.swift            Quick presets + custom + forever
│   ├── BurningLayout.swift         Countdown + stop + display-off
│   ├── PreferencesView.swift       Settings window
│   └── InfoView.swift              "How it works" window
└── Resources/
    ├── burning.png                 Menu bar icon (burning state)
    └── idle.png                    Menu bar icon (idle state)
```

Architecturally every IOKit-touching component sits behind a protocol so the state machine can be unit-tested without actually putting the system to sleep.

## Uninstall

Bonfire's footprint outside `/Applications` is minimal:

- `~/Library/Preferences/ai.dotwise.Bonfire.plist` — user settings
- `/etc/sudoers.d/bonfire-pmset` — *only* if you enabled "Keep awake on battery with lid closed". Remove with:
  ```bash
  sudo rm /etc/sudoers.d/bonfire-pmset
  ```
- `SMAppService` login item — removed automatically when you delete the app

## Known limitations

- **Ad-hoc signed**, not notarized. Gatekeeper warns on first launch; right-click → Open bypasses it.
- **Battery + lid closed mode** modifies system-wide `pmset` policy. If the app crashes mid-session, the next launch will silently reset it; if you remove the sudoers fragment manually, run `sudo pmset -b disablesleep 0` to be safe.
- **External display + lid closed without bypass** already enters "clamshell mode awake" via macOS itself when on AC — Bonfire is redundant but harmless in that setup.

## License

MIT. See [LICENSE](./LICENSE).

## Credits

- Icon: 3D campfire render
- Built with Swift / SwiftUI / IOKit
- Inspired by the long line of macOS "keep awake" tools (Amphetamine, KeepingYouAwake, Lungo, Theine) — Bonfire's distinguishing feature is the **one-prompt-ever sudoers approach** for battery-mode bypass
