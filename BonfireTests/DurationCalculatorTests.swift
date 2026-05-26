import XCTest
@testable import Bonfire

final class DurationCalculatorTests: XCTestCase {
    private func date(_ y: Int, _ m: Int, _ d: Int, _ h: Int, _ min: Int) -> Date {
        var c = DateComponents()
        c.year = y; c.month = m; c.day = d; c.hour = h; c.minute = min
        return Calendar(identifier: .gregorian).date(from: c)!
    }

    func test_untilTime_laterToday() {
        let now = date(2026, 5, 27, 14, 0)
        let result = DurationCalculator.durationUntil(hour: 18, minute: 0, now: now)
        XCTAssertEqual(result, 4 * 3600, accuracy: 0.01)
    }

    func test_untilTime_alreadyPastToday_rollsToTomorrow() {
        let now = date(2026, 5, 27, 23, 30)
        let result = DurationCalculator.durationUntil(hour: 23, minute: 0, now: now)
        XCTAssertEqual(result, 23 * 3600 + 30 * 60, accuracy: 0.01)
    }

    func test_untilTime_exactlyNow_rollsToTomorrow() {
        let now = date(2026, 5, 27, 12, 0)
        let result = DurationCalculator.durationUntil(hour: 12, minute: 0, now: now)
        XCTAssertEqual(result, 24 * 3600, accuracy: 0.01)
    }

    func test_clampDuration_belowMin_clampedToOneMinute() {
        XCTAssertEqual(DurationCalculator.clamped(30), 60)
    }

    func test_clampDuration_aboveMax_clampedTo24h() {
        XCTAssertEqual(DurationCalculator.clamped(48 * 3600), 24 * 3600)
    }

    func test_clampDuration_withinRange_unchanged() {
        XCTAssertEqual(DurationCalculator.clamped(3600), 3600)
    }
}
