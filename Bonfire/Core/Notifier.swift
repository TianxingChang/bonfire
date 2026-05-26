import Foundation
import UserNotifications

enum NotificationKind: CaseIterable, Equatable {
    case timerExpired
    case lowBattery

    var title: String {
        switch self {
        case .timerExpired: return "Bonfire extinguished"
        case .lowBattery:   return "Bonfire extinguished — low battery"
        }
    }

    var body: String {
        switch self {
        case .timerExpired:
            return "Timer ended. Machine may sleep soon."
        case .lowBattery:
            return "Battery is low. Returned to normal sleep behavior."
        }
    }
}

protocol Notifying {
    func requestAuthorization()
    func send(_ kind: NotificationKind)
}

final class SystemNotifier: Notifying {
    func requestAuthorization() {
        UNUserNotificationCenter.current()
            .requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    func send(_ kind: NotificationKind) {
        let content = UNMutableNotificationContent()
        content.title = kind.title
        content.body = kind.body
        let req = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(req, withCompletionHandler: nil)
    }
}

#if DEBUG
final class MockNotifier: Notifying {
    private(set) var authRequested = false
    private(set) var sent: [NotificationKind] = []

    func requestAuthorization() { authRequested = true }
    func send(_ kind: NotificationKind) { sent.append(kind) }
}
#endif
