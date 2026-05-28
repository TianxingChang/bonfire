import XCTest
@testable import Bonfire

@MainActor
final class IdleLayoutTests: XCTestCase {
    func test_canInstantiate() {
        let assert = MockAssertionManager()
        let power = MockPowerMonitor()
        let notify = MockNotifier()
        let bypass = MockBatteryAwakeBypass()
        let prefs = Preferences(store: UserDefaults(suiteName: "IL-\(UUID())")!)
        let ctrl = BonfireController(
            assertionManager: assert, powerMonitor: power, notifier: notify,
            batteryBypass: bypass, preferences: prefs
        )
        _ = IdleLayout(controller: ctrl)
    }

    func test_customDurationFromInputs() {
        XCTAssertEqual(IdleLayout.customDuration(hours: 1, minutes: 30), 5400)
        XCTAssertEqual(IdleLayout.customDuration(hours: 0, minutes: 0), 60)
        XCTAssertEqual(IdleLayout.customDuration(hours: 30, minutes: 0), 24 * 3600)
    }
}
