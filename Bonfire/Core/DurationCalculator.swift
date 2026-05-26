import Foundation

enum DurationCalculator {
    static let minDuration: TimeInterval = 60
    static let maxDuration: TimeInterval = 24 * 3600

    static func durationUntil(hour: Int, minute: Int, now: Date,
                              calendar: Calendar = Calendar(identifier: .gregorian)) -> TimeInterval {
        var components = calendar.dateComponents([.year, .month, .day], from: now)
        components.hour = hour
        components.minute = minute
        components.second = 0
        guard let candidate = calendar.date(from: components) else { return 0 }

        if candidate > now {
            return candidate.timeIntervalSince(now)
        } else {
            let tomorrow = calendar.date(byAdding: .day, value: 1, to: candidate)!
            return tomorrow.timeIntervalSince(now)
        }
    }

    static func clamped(_ duration: TimeInterval) -> TimeInterval {
        min(max(duration, minDuration), maxDuration)
    }
}
