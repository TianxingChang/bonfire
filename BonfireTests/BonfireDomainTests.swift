import XCTest
@testable import Bonfire

final class BonfireDomainTests: XCTestCase {
    func test_burningState_withExpiry_reportsTimeLeft() {
        let now = Date(timeIntervalSince1970: 1_000_000)
        let state = BonfireState.burning(startedAt: now, expiresAt: now.addingTimeInterval(3600))
        XCTAssertEqual(state.timeLeft(now: now.addingTimeInterval(60))!, 3540, accuracy: 0.01)
    }

    func test_burningState_forever_hasNoTimeLeft() {
        let state = BonfireState.burning(startedAt: Date(), expiresAt: nil)
        XCTAssertNil(state.timeLeft(now: Date()))
    }

    func test_idleState_hasNoTimeLeft() {
        XCTAssertNil(BonfireState.idle.timeLeft(now: Date()))
    }
}
