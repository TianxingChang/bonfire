import Foundation
import IOKit.ps

struct PowerSnapshot: Equatable {
    let percent: Int?
    let onAC: Bool
}

protocol PowerMonitoring: AnyObject {
    var onChange: ((PowerSnapshot) -> Void)? { get set }
    func snapshot() -> PowerSnapshot
    func start()
    func stop()
}

final class SystemPowerMonitor: PowerMonitoring {
    var onChange: ((PowerSnapshot) -> Void)?
    private var runLoopSource: CFRunLoopSource?

    func snapshot() -> PowerSnapshot {
        let infoRef = IOPSCopyPowerSourcesInfo()
        guard let info = infoRef?.takeRetainedValue() else {
            return PowerSnapshot(percent: nil, onAC: true)
        }
        guard let list = IOPSCopyPowerSourcesList(info)?.takeRetainedValue() as? [CFTypeRef], !list.isEmpty else {
            return PowerSnapshot(percent: nil, onAC: true)
        }

        var percent: Int?
        var onAC = false
        for source in list {
            guard let desc = IOPSGetPowerSourceDescription(info, source)?.takeUnretainedValue() as? [String: Any] else { continue }
            if let cap = desc[kIOPSCurrentCapacityKey as String] as? Int { percent = cap }
            if let state = desc[kIOPSPowerSourceStateKey as String] as? String,
               state == kIOPSACPowerValue { onAC = true }
        }
        return PowerSnapshot(percent: percent, onAC: onAC)
    }

    func start() {
        guard runLoopSource == nil else { return }
        let context = Unmanaged.passUnretained(self).toOpaque()
        runLoopSource = IOPSNotificationCreateRunLoopSource({ ctx in
            guard let ctx else { return }
            let monitor = Unmanaged<SystemPowerMonitor>.fromOpaque(ctx).takeUnretainedValue()
            monitor.onChange?(monitor.snapshot())
        }, context)?.takeRetainedValue()

        if let source = runLoopSource {
            CFRunLoopAddSource(CFRunLoopGetMain(), source, .defaultMode)
        }
    }

    func stop() {
        if let source = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .defaultMode)
            runLoopSource = nil
        }
    }

    deinit { stop() }
}

#if DEBUG
final class MockPowerMonitor: PowerMonitoring {
    var onChange: ((PowerSnapshot) -> Void)?
    private var current: PowerSnapshot = PowerSnapshot(percent: 100, onAC: true)

    func snapshot() -> PowerSnapshot { current }
    func start() {}
    func stop() {}

    func simulate(percent: Int?, onAC: Bool) {
        current = PowerSnapshot(percent: percent, onAC: onAC)
        onChange?(current)
    }
}
#endif
