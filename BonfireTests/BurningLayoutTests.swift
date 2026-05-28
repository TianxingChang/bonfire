import XCTest
import SwiftUI
@testable import Bonfire

@MainActor
final class BurningLayoutTests: XCTestCase {
    func test_canInstantiate() {
        let assert = MockAssertionManager()
        let power = MockPowerMonitor()
        let notify = MockNotifier()
        let bypass = MockBatteryAwakeBypass()
        let prefs = Preferences(store: UserDefaults(suiteName: "BL-\(UUID())")!)
        let ctrl = BonfireController(
            assertionManager: assert, powerMonitor: power, notifier: notify,
            batteryBypass: bypass, preferences: prefs
        )
        try? ctrl.start(mode: .forever)
        _ = BurningLayout(controller: ctrl)
        XCTAssertTrue(true)
    }

    func test_formatRemaining_underAnHour_isMinutesOnly() {
        XCTAssertEqual(BurningLayout.formatRemaining(45 * 60), "45m left")
    }

    func test_formatRemaining_overAnHour_isHoursAndMinutes() {
        XCTAssertEqual(BurningLayout.formatRemaining(3600 + 23 * 60), "1h 23m left")
    }

    func test_formatRemaining_nil_isForeverLabel() {
        XCTAssertEqual(BurningLayout.formatRemaining(nil), "no timer")
    }

    func test_formatElapsed_isCompact() {
        XCTAssertEqual(BurningLayout.formatElapsed(3600 + 5 * 60), "1h 5m")
        XCTAssertEqual(BurningLayout.formatElapsed(45), "0m")
        XCTAssertEqual(BurningLayout.formatElapsed(120), "2m")
    }
}
