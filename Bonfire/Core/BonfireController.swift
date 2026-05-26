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
    private let preferences: Preferences
    private let clock: Clock

    init(
        assertionManager: AssertionManaging,
        powerMonitor: PowerMonitoring,
        notifier: Notifying,
        preferences: Preferences,
        clock: Clock = SystemClock()
    ) {
        self.assertionManager = assertionManager
        self.powerMonitor = powerMonitor
        self.notifier = notifier
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
    }

    func stop(reason: StopReason) {
        guard state.isBurning else { return }
        assertionManager.release()
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
        guard state.isBurning, !snap.onAC,
              let percent = snap.percent,
              percent < preferences.lowBatteryThreshold else { return }
        stop(reason: .lowBattery)
    }
}
