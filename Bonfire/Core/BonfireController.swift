import Foundation
import Combine

protocol Clock {
    var now: Date { get }
}

struct SystemClock: Clock {
    var now: Date { Date() }
}

@MainActor
final class BonfireController: ObservableObject {
    @Published private(set) var state: BonfireState = .idle

    private let assertionManager: AssertionManaging
    private let powerMonitor: PowerMonitoring
    private let notifier: Notifying
    private let batteryBypass: BatteryAwakeBypassing
    private let preferences: Preferences
    private let clock: Clock

    init(
        assertionManager: AssertionManaging,
        powerMonitor: PowerMonitoring,
        notifier: Notifying,
        batteryBypass: BatteryAwakeBypassing,
        preferences: Preferences,
        clock: Clock = SystemClock()
    ) {
        self.assertionManager = assertionManager
        self.powerMonitor = powerMonitor
        self.notifier = notifier
        self.batteryBypass = batteryBypass
        self.preferences = preferences
        self.clock = clock
        self.powerMonitor.onChange = { [weak self] snap in
            MainActor.assumeIsolated { self?.handlePowerChange(snap) }
        }
    }

    func start(mode: StartMode) throws {
        try assertionManager.acquire(reason: "Bonfire: keeping system awake")
        let now = clock.now
        switch mode {
        case .duration(let seconds):
            let clamped = DurationCalculator.clamped(seconds)
            state = .burning(startedAt: now, expiresAt: now.addingTimeInterval(clamped))
        case .forever:
            state = .burning(startedAt: now, expiresAt: nil)
        }
        // Engage the v2 battery bypass if user opted in AND we're on battery.
        // On AC, the IOPMAssertion already handles closed-clamshell awake.
        if preferences.batteryBypassEnabled && !powerMonitor.snapshot().onAC {
            try? batteryBypass.enable()
        }
    }

    func stop(reason: StopReason) {
        guard state.isBurning else { return }
        assertionManager.release()
        batteryBypass.disable()   // no-op if it was never engaged
        state = .idle
        switch reason {
        case .userRequested: break
        case .timerExpired:
            if preferences.notifyOnEnd { notifier.send(.timerExpired) }
        case .lowBattery:
            if preferences.notifyOnEnd { notifier.send(.lowBattery) }
        }
    }

    func tick() {
        guard case let .burning(_, expiresAt) = state, let expiresAt else { return }
        if clock.now >= expiresAt {
            stop(reason: .timerExpired)
        }
    }

    private func handlePowerChange(_ snap: PowerSnapshot) {
        // 1. Low-battery cutoff (highest priority — stops everything)
        if state.isBurning, !snap.onAC,
           let percent = snap.percent,
           percent < preferences.lowBatteryThreshold {
            stop(reason: .lowBattery)
            return
        }

        // 2. AC ↔ battery transitions: engage/disengage the bypass if needed.
        //    Only meaningful while burning AND the user enabled the pref.
        guard state.isBurning, preferences.batteryBypassEnabled else { return }
        if !snap.onAC && !batteryBypass.isEnabled {
            try? batteryBypass.enable()
        } else if snap.onAC && batteryBypass.isEnabled {
            batteryBypass.disable()
        }
    }
}
