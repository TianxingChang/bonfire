import Foundation

enum BonfireState: Equatable {
    case idle
    case burning(startedAt: Date, expiresAt: Date?)

    var isBurning: Bool {
        if case .burning = self { return true }
        return false
    }

    func timeLeft(now: Date) -> TimeInterval? {
        guard case let .burning(_, expiresAt) = self, let expiresAt else { return nil }
        return max(0, expiresAt.timeIntervalSince(now))
    }

    func runningTime(now: Date) -> TimeInterval? {
        guard case let .burning(startedAt, _) = self else { return nil }
        return max(0, now.timeIntervalSince(startedAt))
    }
}

enum StartMode: Equatable {
    case duration(TimeInterval)
    case forever
}

enum StopReason: Equatable {
    case userRequested
    case timerExpired
    case lowBattery
}
