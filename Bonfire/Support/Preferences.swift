import Foundation
import Combine

final class Preferences: ObservableObject {
    private enum Key {
        static let lowBatteryThreshold  = "bonfire.lowBatteryThreshold"
        static let notifyOnEnd          = "bonfire.notifyOnEnd"
        static let launchAtLogin        = "bonfire.launchAtLogin"
        static let batteryBypassEnabled = "bonfire.batteryBypassEnabled"
    }

    static let allowedThresholds: [Int] = [10, 15, 20, 30]

    private let store: UserDefaults

    @Published var lowBatteryThreshold: Int {
        didSet {
            let clamped = Preferences.clampThreshold(lowBatteryThreshold)
            if clamped != lowBatteryThreshold {
                lowBatteryThreshold = clamped
                return
            }
            store.set(lowBatteryThreshold, forKey: Key.lowBatteryThreshold)
        }
    }
    @Published var notifyOnEnd: Bool {
        didSet { store.set(notifyOnEnd, forKey: Key.notifyOnEnd) }
    }
    @Published var launchAtLogin: Bool {
        didSet { store.set(launchAtLogin, forKey: Key.launchAtLogin) }
    }
    @Published var batteryBypassEnabled: Bool {
        didSet { store.set(batteryBypassEnabled, forKey: Key.batteryBypassEnabled) }
    }

    init(store: UserDefaults = .standard) {
        self.store = store
        let storedThreshold = store.object(forKey: Key.lowBatteryThreshold) as? Int
        self.lowBatteryThreshold = Preferences.clampThreshold(storedThreshold ?? 20)
        self.notifyOnEnd = (store.object(forKey: Key.notifyOnEnd) as? Bool) ?? true
        self.launchAtLogin = (store.object(forKey: Key.launchAtLogin) as? Bool) ?? true
        self.batteryBypassEnabled = (store.object(forKey: Key.batteryBypassEnabled) as? Bool) ?? false
    }

    private static func clampThreshold(_ value: Int) -> Int {
        let allowed = allowedThresholds
        if let lower = allowed.last(where: { $0 <= value }) {
            return min(lower, allowed.last!)
        }
        return allowed.first!
    }
}
