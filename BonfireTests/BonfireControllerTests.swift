import XCTest
@testable import Bonfire

@MainActor
final class BonfireControllerTests: XCTestCase {
    private var assert: MockAssertionManager!
    private var power: MockPowerMonitor!
    private var notify: MockNotifier!
    private var prefs: Preferences!
    private var controller: BonfireController!
    private var clock: TestClock!

    override func setUp() async throws {
        assert = MockAssertionManager()
        power = MockPowerMonitor()
        notify = MockNotifier()
        prefs = Preferences(store: UserDefaults(suiteName: "BonfireCtrl-\(UUID().uuidString)")!)
        clock = TestClock(now: Date(timeIntervalSince1970: 1_000_000))
        controller = BonfireController(
            assertionManager: assert,
            powerMonitor: power,
            notifier: notify,
            preferences: prefs,
            clock: clock
        )
    }

    func test_startDuration_acquiresAssertionAndBecomesBurning() throws {
        try controller.start(mode: .duration(3600))
        XCTAssertEqual(assert.acquireCount, 1)
        XCTAssertTrue(controller.state.isBurning)
    }

    func test_startForever_hasNoExpiry() throws {
        try controller.start(mode: .forever)
        if case let .burning(_, expiresAt) = controller.state {
            XCTAssertNil(expiresAt)
        } else { XCTFail("expected burning") }
    }

    func test_userStop_releasesAndDoesNotNotify() throws {
        try controller.start(mode: .duration(3600))
        controller.stop(reason: .userRequested)
        XCTAssertEqual(assert.releaseCount, 1)
        XCTAssertEqual(controller.state, .idle)
        XCTAssertTrue(notify.sent.isEmpty)
    }

    func test_timerExpiry_releasesAndNotifies() throws {
        try controller.start(mode: .duration(60))
        clock.advance(by: 61)
        controller.tick()
        XCTAssertEqual(controller.state, .idle)
        XCTAssertEqual(notify.sent, [.timerExpired])
    }

    func test_foreverMode_doesNotExpire() throws {
        try controller.start(mode: .forever)
        clock.advance(by: 99_999)
        controller.tick()
        XCTAssertTrue(controller.state.isBurning)
        XCTAssertTrue(notify.sent.isEmpty)
    }

    func test_batteryDropsBelowThreshold_extinguishesAndNotifies() throws {
        try controller.start(mode: .duration(3600))
        power.simulate(percent: 19, onAC: false)
        XCTAssertEqual(controller.state, .idle)
        XCTAssertEqual(notify.sent, [.lowBattery])
    }

    func test_batteryStaysAboveThreshold_doesNothing() throws {
        try controller.start(mode: .duration(3600))
        power.simulate(percent: 21, onAC: false)
        XCTAssertTrue(controller.state.isBurning)
    }

    func test_idleStateIgnoresBatteryEvents() {
        power.simulate(percent: 5, onAC: false)
        XCTAssertEqual(controller.state, .idle)
        XCTAssertTrue(notify.sent.isEmpty)
    }

    func test_notificationsOptedOut_suppressesAll() throws {
        prefs.notifyOnEnd = false
        try controller.start(mode: .duration(60))
        clock.advance(by: 61)
        controller.tick()
        XCTAssertTrue(notify.sent.isEmpty)
    }
}

final class TestClock: Clock {
    private(set) var now: Date
    init(now: Date) { self.now = now }
    func advance(by seconds: TimeInterval) { now = now.addingTimeInterval(seconds) }
}
