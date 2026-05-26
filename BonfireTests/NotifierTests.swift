import XCTest
@testable import Bonfire

final class NotifierTests: XCTestCase {
    func test_mockNotifier_recordsSentMessages() {
        let n = MockNotifier()
        n.send(.timerExpired)
        n.send(.lowBattery)
        XCTAssertEqual(n.sent, [.timerExpired, .lowBattery])
    }

    func test_notificationKind_titleAndBody_areNonEmpty() {
        for kind in NotificationKind.allCases {
            XCTAssertFalse(kind.title.isEmpty)
            XCTAssertFalse(kind.body.isEmpty)
        }
    }
}
