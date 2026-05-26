import Foundation
import IOKit
import IOKit.pwr_mgt

protocol AssertionManaging {
    var isHeld: Bool { get }
    func acquire(reason: String) throws
    func release()
}

enum AssertionError: Error {
    case ioReturnFailure(IOReturn)
}

final class SystemAssertionManager: AssertionManaging {
    private var idleID: IOPMAssertionID = IOPMAssertionID(0)
    private var systemID: IOPMAssertionID = IOPMAssertionID(0)
    private(set) var isHeld: Bool = false

    func acquire(reason: String) throws {
        if isHeld { return }

        let r1 = IOPMAssertionCreateWithName(
            kIOPMAssertionTypePreventUserIdleSystemSleep as CFString,
            IOPMAssertionLevel(kIOPMAssertionLevelOn),
            reason as CFString,
            &idleID
        )
        guard r1 == kIOReturnSuccess else { throw AssertionError.ioReturnFailure(r1) }

        let r2 = IOPMAssertionCreateWithName(
            kIOPMAssertionTypePreventSystemSleep as CFString,
            IOPMAssertionLevel(kIOPMAssertionLevelOn),
            reason as CFString,
            &systemID
        )
        if r2 != kIOReturnSuccess {
            IOPMAssertionRelease(idleID)
            idleID = IOPMAssertionID(0)
            throw AssertionError.ioReturnFailure(r2)
        }

        isHeld = true
    }

    func release() {
        if idleID != 0 {
            IOPMAssertionRelease(idleID)
            idleID = IOPMAssertionID(0)
        }
        if systemID != 0 {
            IOPMAssertionRelease(systemID)
            systemID = IOPMAssertionID(0)
        }
        isHeld = false
    }

    deinit { release() }
}

#if DEBUG
final class MockAssertionManager: AssertionManaging {
    private(set) var isHeld: Bool = false
    var acquireCount = 0
    var releaseCount = 0
    var lastReason: String?

    func acquire(reason: String) throws {
        acquireCount += 1
        lastReason = reason
        isHeld = true
    }

    func release() {
        releaseCount += 1
        isHeld = false
    }
}
#endif
