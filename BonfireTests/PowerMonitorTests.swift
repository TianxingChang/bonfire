import XCTest
@testable import Bonfire

final class PowerMonitorTests: XCTestCase {
    func test_realMonitor_returnsBatterySnapshot() {
        let mon = SystemPowerMonitor()
        let snap = mon.snapshot()
        XCTAssertNotNil(snap)
    }

    func test_mockMonitor_firesCallbackOnBatteryChange() {
        let mock = MockPowerMonitor()
        var called = false
        mock.onChange = { _ in called = true }
        mock.simulate(percent: 19, onAC: false)
        XCTAssertTrue(called)
    }
}
