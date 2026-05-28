import XCTest
@testable import Bonfire

final class PreferencesTests: XCTestCase {
    private var prefs: Preferences!
    private var store: UserDefaults!

    override func setUp() {
        store = UserDefaults(suiteName: "BonfireTests-\(UUID().uuidString)")!
        prefs = Preferences(store: store)
    }

    func test_defaults() {
        XCTAssertEqual(prefs.lowBatteryThreshold, 20)
        XCTAssertTrue(prefs.notifyOnEnd)
        XCTAssertTrue(prefs.launchAtLogin)
        XCTAssertFalse(prefs.batteryBypassEnabled)   // v2 opt-in, off by default
    }

    func test_setAndPersist() {
        prefs.lowBatteryThreshold = 30
        prefs.notifyOnEnd = false
        prefs.batteryBypassEnabled = true
        let reloaded = Preferences(store: store)
        XCTAssertEqual(reloaded.lowBatteryThreshold, 30)
        XCTAssertFalse(reloaded.notifyOnEnd)
        XCTAssertTrue(reloaded.batteryBypassEnabled)
    }

    func test_thresholdClamping() {
        prefs.lowBatteryThreshold = 5
        XCTAssertEqual(prefs.lowBatteryThreshold, 10)
        prefs.lowBatteryThreshold = 99
        XCTAssertEqual(prefs.lowBatteryThreshold, 30)
    }
}
