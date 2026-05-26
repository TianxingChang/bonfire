import XCTest
@testable import Bonfire

final class AssertionManagerTests: XCTestCase {
    func test_realManager_acquireThenRelease_changesIsHeld() throws {
        let mgr = SystemAssertionManager()
        XCTAssertFalse(mgr.isHeld)
        try mgr.acquire(reason: "test")
        XCTAssertTrue(mgr.isHeld)
        mgr.release()
        XCTAssertFalse(mgr.isHeld)
    }

    func test_realManager_acquireTwice_isIdempotent() throws {
        let mgr = SystemAssertionManager()
        try mgr.acquire(reason: "test")
        try mgr.acquire(reason: "test")
        XCTAssertTrue(mgr.isHeld)
        mgr.release()
        XCTAssertFalse(mgr.isHeld)
    }

    func test_realManager_releaseWithoutAcquire_isNoop() {
        let mgr = SystemAssertionManager()
        mgr.release()
        XCTAssertFalse(mgr.isHeld)
    }
}
