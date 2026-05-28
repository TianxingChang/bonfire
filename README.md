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

## Usage

Click the campfire icon in your menu bar:

**Keep your Mac awake for a fixed time** — click `30m`, `1h`, `2h`, `4h`, or open `Custom ▾` to dial any duration. Bonfire flips to the burning view showing a live countdown. When the timer expires it stops automatically and your Mac returns to normal sleep behavior.

**Keep your Mac awake indefinitely** — click `Keep awake`. Click `Stop` when you're done.

**Pre-emptively turn the screen off** (while keeping the system running) — in the burning view, click `Turn off display`. Useful before closing the lid and walking away. Move the mouse or press a key to wake the screen again.

### What happens while Bonfire is active

- Your Mac stays awake the whole time, even if you don't touch it.
- The screen may still dim or turn off on its own — that's fine, your Mac keeps running underneath.
- **Closing the lid keeps it running too — but only when plugged in.** On battery, closing the lid still puts your Mac to sleep, unless you opt into the advanced battery mode below.
- On battery, Bonfire stops itself when battery drops below your threshold (default 20%) so an unattended run can never drain to zero.
- The timer survives lid close, screen off, and your absence — it lives in the menu bar app's process, not in anything UI-bound.

### Advanced: battery mode (lid closed, on battery)

By default, macOS forces sleep when you close the lid on battery — there's no way around this from a normal app. Bonfire offers an opt-in workaround:

1. Open `Preferences…` → toggle on **Keep awake on battery with lid closed**.
2. The next time you start a session on battery, Bonfire asks for your admin password **once** to install a small `sudoers` fragment.
3. From then on, lid-closed-on-battery just works, silently, forever — across app restarts and reboots.

The fragment grants the admin group passwordless access to **exactly the two pmset commands Bonfire needs**, nothing else:

```
%admin ALL = (root) NOPASSWD: /usr/bin/pmset -b disablesleep 0, /usr/bin/pmset -b disablesleep 1
```

To revoke at any time: `sudo rm /etc/sudoers.d/bonfire-pmset`.

⚠️ Battery still drains. The low-battery auto-stop rail still applies — Bonfire turns itself off when battery hits your threshold.

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
