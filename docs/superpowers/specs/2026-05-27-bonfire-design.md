# Bonfire — PRD v0.1

**Date:** 2026-05-27
**Status:** Draft for review
**Owner:** terry@dotwise.ai

A macOS menu bar app that keeps the system awake on demand — built for "vibe coding" sessions where you kick off a long task and walk away with the lid closed.

---

## 1. Background & Goals

### Problem
Long-running background tasks during coding sessions (Claude Code agents, builds, local model runs) get killed by macOS's default sleep behavior:
- Closing the lid puts the machine to sleep, killing the task
- Leaving the lid open burns power and is distracting

The built-in `caffeinate` command works but requires a terminal session, has no timer, and no UI surface.

### Goal
A lightweight menu bar app that toggles "keep awake" with one click, supports timers, and is safe to use on battery.

### Non-Goals (v1)
- Preventing display sleep (user explicitly accepts the screen going dark)
- Battery-mode lid-close-awake (deferred to v2; needs a privileged helper tool)
- Desktop pet / character animations
- iCloud sync or multi-device config
- Anti-screensaver / anti-lockscreen
- Mac App Store distribution

---

## 2. User Scenarios

1. **Typical** — User clicks the "2h" preset, closes the lid, leaves for a meeting. Returns to find the task still running. The machine has since returned to normal sleep behavior automatically.
2. **Open-ended** — User toggles "Keep Burning" (forever mode), stops manually when done.
3. **Deadline** — User picks "Until 23:00".
4. **Plan change** — User started a 2h timer, decides to extend. Must Extinguish first, then start a new timer (simpler UI, no overwrite logic).

---

## 3. Scope

### 3.1 Menu Bar Icon
- Two states, using **custom template images** (single-color, system auto-inverts for dark/light menu bar):
  - **Idle**: two crossed logs (firewood, no flame)
  - **Burning**: same logs with a flame on top
- Assets shipped as `LogsIdle` and `LogsBurning` in `Assets.xcassets`, marked as Template Image, ~18×18pt at @1x/@2x
- Left-click → opens popover
- Right-click → standard menu (Quick toggle, Quit, Preferences)

### 3.2 Popover

The popover has two layouts driven by state:

**Idle state** — shows all start options:
```
┌─────────────────────────────────┐
│  🔥 Bonfire — Idle              │
│                                 │
│  Quick: [30m][1h][2h][4h]       │
│  Custom: [1] h [30] m  [Start]  │
│  Until:  [23:00 ▾]      [Start] │
│  [ ∞ Keep Burning ]             │
│                                 │
│  [ ⚙ Preferences ]              │
└─────────────────────────────────┘
```

**Burning state** — shows status + single extinguish action:
```
┌─────────────────────────────────┐
│  🔥 Bonfire — Burning           │
│  Running 23m · 1h 37m left      │
│                                 │
│  [ ⏹ Extinguish ]               │
│                                 │
│  [ ⚙ Preferences ]              │
└─────────────────────────────────┘
```

- Status line refreshes every 1s while popover is open
- "Forever" mode shows `Running 23m · no timer` (no countdown)

### 3.3 Timer Modes
| Mode    | Behavior                                            |
| ------- | --------------------------------------------------- |
| Preset  | Creates `IOPMAssertion`, schedules release at T+N   |
| Custom  | Same as preset, N from user input (h + m)           |
| Until   | Computes `target - now`, same as preset             |
| Forever | Creates `IOPMAssertion`, no scheduled release       |

Min duration: 1 minute. Max: 24 hours (custom input clamped).

**"Until" rollover rule:** If the picked time has already passed today (e.g., it's 23:30 and user picks 23:00), interpret as 23:00 *tomorrow*. The duration is always `nextOccurrence(time) - now`.

### 3.4 Battery Protection
- Threshold default: **20%** (Preferences: 10 / 15 / 20 / 30)
- On crossing threshold downward while Burning:
  - Release assertion
  - Send notification: "Battery below 20%. Bonfire extinguished — machine may sleep soon."
  - Transition to Idle state
- Re-plugging power does **not** automatically restart (avoids flapping at threshold)
- User restarts manually if desired

### 3.5 Notifications
Triggered by:
- Timer expiry (Preset / Custom / Until)
- Low-battery auto-extinguish

NOT triggered by:
- Manual Extinguish click
- App quit

Implementation: `UserNotifications` framework. Permission requested on first start; if denied, app still works but silently.

### 3.6 Preferences
A standard SwiftUI settings window with:
- **Start at login** (default: ON) — via `SMAppService.mainApp`
- **Low battery threshold** (10 / 15 / 20 / 30 — default 20)
- **End-of-timer notifications** (default: ON)
- **About** section: version, link to GitHub (when public)

---

## 4. Technical Architecture

### Component Diagram
```
┌──────────────────────────────────────────┐
│  BonfireApp (SwiftUI @main)              │
│  └─ MenuBarExtra (.window)               │
│      ├─ StatusIconView (idle/burning)    │
│      └─ PopoverView                      │
│          ├─ IdleLayout                   │
│          │   ├─ QuickPresetButtons       │
│          │   ├─ CustomDurationInput      │
│          │   ├─ UntilTimeInput           │
│          │   └─ ForeverButton            │
│          └─ BurningLayout                │
│              ├─ StatusText               │
│              └─ ExtinguishButton         │
└──────────────────────────────────────────┘
                  │ observes
                  ▼
┌──────────────────────────────────────────┐
│  BonfireController : ObservableObject    │
│    @Published state: BonfireState        │
│    func start(mode: StartMode)           │
│    func stop(reason: StopReason)         │
└──────────────────────────────────────────┘
        │             │              │
        ▼             ▼              ▼
┌──────────────┐ ┌──────────┐ ┌────────────────┐
│ Assertion    │ │ Timer    │ │ PowerMonitor   │
│ Manager      │ │ Engine   │ │ (IOPS callback)│
│ (IOKit)      │ │          │ │                │
└──────────────┘ └──────────┘ └────────────────┘
                                    │
                          on low battery threshold
                                    ▼
                         controller.stop(.lowBattery)
                         Notifier.send(.lowBattery)
```

### State Machine
```
enum BonfireState {
    case idle
    case burning(startedAt: Date, expiresAt: Date?)  // nil expiresAt = forever
}

enum StartMode {
    case duration(TimeInterval)  // covers preset, custom, until (caller computes)
    case forever
}

enum StopReason {
    case userRequested      // no notification
    case timerExpired       // notify
    case lowBattery         // notify
}
```

### Key APIs

| Concern               | API                                                                  |
| --------------------- | -------------------------------------------------------------------- |
| Keep system awake     | `IOPMAssertionCreateWithName` + `IOPMAssertionRelease`               |
| Assertion type        | `kIOPMAssertionTypePreventUserIdleSystemSleep` + `kIOPMAssertionTypePreventSystemSleep` (both) |
| Battery state         | `IOPSCopyPowerSourcesInfo`, `IOPSGetTimeRemainingEstimate`           |
| Battery change events | `IOPSNotificationCreateRunLoopSource`                                |
| Notifications         | `UNUserNotificationCenter`                                           |
| Start at login        | `SMAppService.mainApp.register()`                                    |
| Menu bar UI           | `MenuBarExtra(.window)` (SwiftUI, macOS 13+)                         |

### Minimum macOS
**13.0 (Ventura)** — required for `MenuBarExtra` and `SMAppService`.

### Project Structure
```
Bonfire/
├── BonfireApp.swift                # @main entry
├── Views/
│   ├── PopoverView.swift           # routes to IdleLayout / BurningLayout
│   ├── IdleLayout.swift
│   ├── BurningLayout.swift
│   └── PreferencesView.swift
├── Core/
│   ├── BonfireController.swift     # state machine, public API
│   ├── AssertionManager.swift      # IOKit wrapper, owns the IOPMAssertionID
│   ├── PowerMonitor.swift          # IOPS subscription, low-battery callback
│   └── Notifier.swift              # UNUserNotificationCenter wrapper
├── Support/
│   ├── LaunchAtLogin.swift         # SMAppService wrapper
│   └── Preferences.swift           # @AppStorage-backed settings
└── Resources/
    └── Assets.xcassets
```

Each Core module owns one concern, exposes a narrow API, and is unit-testable independently (Assertion / Power can be mocked with protocols).

---

## 5. Known Limitations

Documented in README so users aren't surprised:

1. **On battery + lid closed → machine still sleeps.** v1 limitation. v2 may add a privileged helper tool to flip `pmset -b disablesleep`. Workaround: plug in power.
2. **External display + AC + keyboard → already in clamshell-mode-awake.** Bonfire is redundant but harmless in that setup.
3. **Enterprise MDM forced lock-screen policies are NOT bypassed.** Out of scope.
4. **App crash → assertion released automatically.** This is a feature of `IOPMAssertion` (no leaked system state — contrast with `pmset` approaches).

---

## 6. Acceptance Criteria

1. **AC + preset:** Plug in power, click "2h", close lid. After 2h: task still ran to completion. Notification was delivered. Machine has returned to normal sleep policy (verifiable via `pmset -g assertions`).
2. **Battery + low battery cutoff:** On battery, click "1h". Drain to ≤20%. App releases assertion, sends notification, returns to Idle state.
3. **Forever mode lifecycle:** Toggle Forever. Verify `pmset -g assertions | grep Bonfire` shows the assertion. Quit app via menu → assertion is gone within 1s.
4. **Crash recovery:** Force-kill app while Burning (e.g., `kill -9` from Activity Monitor). Verify no leaked assertions remain in `pmset -g assertions`.
5. **Start at login:** Enable in Preferences. Log out and back in. Bonfire appears in menu bar automatically.
6. **Permission graceful degradation:** Deny notification permission. Trigger timer expiry. App still releases assertion correctly; no notification is sent (no crash).

---

## 7. Out of Scope / Future Versions

- **v2 — battery-mode lid-close-awake**: privileged helper tool via `SMAppService.daemon` to toggle `pmset -b disablesleep`. Crash recovery contract: helper restores setting on parent app exit OR on its own timeout (whichever first).
- **v2.x** — display-sleep prevention as an opt-in toggle (`kIOPMAssertionTypeNoDisplaySleep`).
- **v3** — "auto-burn while these apps are running" rules.
- **Maybe never** — Mac App Store distribution (requires sandboxing, may complicate IOKit usage; not worth it for a personal tool).
