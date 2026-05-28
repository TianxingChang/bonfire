import Foundation

/// Overrides macOS's "lid close → sleep" policy on battery via `pmset -b disablesleep`.
///
/// This is the v2 capability the PRD's §7 talked about. It's gated behind a
/// Preferences toggle because:
///   - Each enable requires admin-priv shell out (`do shell script ... with
///     administrator privileges`), which may prompt for password.
///   - Modifying system sleep policy can drain battery much faster than usual.
///
/// AC-mode lid-close already works via `IOPMAssertion` (see `AssertionManager`),
/// so this bypass is only meaningful on battery.
protocol BatteryAwakeBypassing: AnyObject {
    var isEnabled: Bool { get }
    func enable() throws
    func disable()
    /// Best-effort cleanup on app launch: if a previous run crashed without
    /// resetting `disablesleep`, the machine would never sleep until manually
    /// fixed. This reads current state and rolls it back if needed.
    func resetIfLeftEnabled()
}

enum BatteryAwakeBypassError: Error, Equatable {
    case authorizationDenied
    case shellFailed(Int32)
}

final class SystemBatteryAwakeBypass: BatteryAwakeBypassing {
    private(set) var isEnabled = false

    func enable() throws {
        guard !isEnabled else { return }
        try runAdmin("/usr/bin/pmset -b disablesleep 1")
        isEnabled = true
    }

    func disable() {
        guard isEnabled else { return }
        do {
            try runAdmin("/usr/bin/pmset -b disablesleep 0")
        } catch {
            NSLog("Bonfire: failed to restore pmset disablesleep: \(error)")
        }
        isEnabled = false
    }

    func resetIfLeftEnabled() {
        guard readDisableSleepFlag() else { return }
        do {
            try runAdmin("/usr/bin/pmset -b disablesleep 0")
            NSLog("Bonfire: cleaned up leftover pmset disablesleep=1 from a previous run")
        } catch {
            NSLog("Bonfire: couldn't reset leftover pmset disablesleep: \(error)")
        }
    }

    // MARK: - Helpers

    /// Reads `pmset -g disablesleep` (read-only, no privileges needed) and
    /// returns true if the flag is currently set to 1.
    private func readDisableSleepFlag() -> Bool {
        let task = Process()
        task.launchPath = "/usr/bin/pmset"
        task.arguments = ["-g", "disablesleep"]
        let pipe = Pipe()
        task.standardOutput = pipe
        do {
            try task.run()
            task.waitUntilExit()
        } catch {
            return false
        }
        guard let output = String(
            data: pipe.fileHandleForReading.readDataToEndOfFile(),
            encoding: .utf8
        ) else { return false }
        for line in output.split(separator: "\n")
            where line.lowercased().contains("disablesleep") {
            return line.trimmingCharacters(in: .whitespaces).hasSuffix("1")
        }
        return false
    }

    /// Runs a shell command with administrator privileges via AppleScript.
    /// macOS caches the credential for ~5 min, so back-to-back enable/disable
    /// usually only prompts once.
    private func runAdmin(_ command: String) throws {
        let escaped = command.replacingOccurrences(of: "\"", with: "\\\"")
        let source = "do shell script \"\(escaped)\" with administrator privileges"
        guard let script = NSAppleScript(source: source) else {
            throw BatteryAwakeBypassError.shellFailed(-1)
        }
        var errInfo: NSDictionary?
        script.executeAndReturnError(&errInfo)
        if let info = errInfo {
            let code = (info[NSAppleScript.errorNumber] as? Int32) ?? -1
            if code == -128 {
                throw BatteryAwakeBypassError.authorizationDenied
            }
            throw BatteryAwakeBypassError.shellFailed(code)
        }
    }
}

#if DEBUG
final class MockBatteryAwakeBypass: BatteryAwakeBypassing {
    private(set) var isEnabled = false
    var enableCount = 0
    var disableCount = 0
    var resetCount = 0
    var enableShouldThrow: BatteryAwakeBypassError?

    func enable() throws {
        if let error = enableShouldThrow { throw error }
        enableCount += 1
        isEnabled = true
    }

    func disable() {
        disableCount += 1
        isEnabled = false
    }

    func resetIfLeftEnabled() {
        resetCount += 1
    }
}
#endif
