import Foundation

/// Overrides macOS's "lid close on battery → forced sleep" via `pmset -b disablesleep`.
///
/// Strategy: on first enable, install a tiny `/etc/sudoers.d/bonfire-pmset`
/// fragment granting passwordless sudo for the two specific pmset variants
/// (`disablesleep 0` and `disablesleep 1`). That requires admin authentication
/// **once, ever**. After install, every enable/disable is a silent
/// `sudo -n /usr/bin/pmset …` with no prompts.
///
/// This is dramatically better UX than calling `do shell script with administrator
/// privileges` each time — AppleScript's auth caching is per-script-instance and
/// effectively prompts every call.
///
/// Safety:
///   - Sudoers grant is narrow: only `/usr/bin/pmset -b disablesleep 0` and `… 1`
///   - The fragment is syntax-validated with `visudo -c` before being installed
///   - `resetIfLeftEnabled()` at launch recovers from app crashes that left
///     disablesleep=1 (uses the passwordless path; silent failure if uninstalled)
///   - Remove anytime: `sudo rm /etc/sudoers.d/bonfire-pmset`
protocol BatteryAwakeBypassing: AnyObject {
    var isEnabled: Bool { get }
    func enable() throws
    func disable()
    func resetIfLeftEnabled()
}

enum BatteryAwakeBypassError: Error, Equatable {
    case authorizationDenied
    case shellFailed(Int32)
    case sudoersInstallFailed
}

final class SystemBatteryAwakeBypass: BatteryAwakeBypassing {
    private(set) var isEnabled = false

    private let sudoersPath = "/etc/sudoers.d/bonfire-pmset"
    private let pmsetPath = "/usr/bin/pmset"

    // MARK: - Public

    func enable() throws {
        guard !isEnabled else { return }
        if !tryPasswordlessPmset(args: ["-b", "disablesleep", "1"]) {
            try installSudoersFragment()   // may prompt admin password (one time)
            guard tryPasswordlessPmset(args: ["-b", "disablesleep", "1"]) else {
                throw BatteryAwakeBypassError.sudoersInstallFailed
            }
        }
        isEnabled = true
    }

    func disable() {
        guard isEnabled else { return }
        _ = tryPasswordlessPmset(args: ["-b", "disablesleep", "0"])
        isEnabled = false   // mark off either way to avoid stuck state
    }

    func resetIfLeftEnabled() {
        guard currentDisableSleepIsOn() else { return }
        if tryPasswordlessPmset(args: ["-b", "disablesleep", "0"]) {
            NSLog("Bonfire: reset leftover pmset disablesleep=1 silently")
        } else {
            NSLog("""
            Bonfire: detected leftover pmset disablesleep=1 but the sudoers
            fragment isn't installed. Run this manually to reset:
                sudo pmset -b disablesleep 0
            """)
        }
    }

    // MARK: - Passwordless sudo path

    /// Tries `sudo -n /usr/bin/pmset <args>`. `-n` means "non-interactive,
    /// fail immediately if a password would be needed". Returns true iff
    /// the command exited 0.
    private func tryPasswordlessPmset(args: [String]) -> Bool {
        let task = Process()
        task.launchPath = "/usr/bin/sudo"
        task.arguments = ["-n", pmsetPath] + args
        task.standardOutput = Pipe()
        task.standardError = Pipe()
        do {
            try task.run()
        } catch {
            return false
        }
        task.waitUntilExit()
        return task.terminationStatus == 0
    }

    /// Writes /etc/sudoers.d/bonfire-pmset granting %admin NOPASSWD for the two
    /// specific pmset invocations. Validated with `visudo -c` before install.
    /// Prompts admin password ONCE via AppleScript.
    private func installSudoersFragment() throws {
        let content = """
        # Installed by Bonfire (https://github.com/dotwise/bonfire) to allow
        # toggling pmset disablesleep without a password prompt. Narrow grant:
        # only these two exact invocations are passwordless.
        #
        # Remove with: sudo rm /etc/sudoers.d/bonfire-pmset
        %admin ALL = (root) NOPASSWD: /usr/bin/pmset -b disablesleep 0, /usr/bin/pmset -b disablesleep 1
        """
        let tmpPath = (NSTemporaryDirectory() as NSString)
            .appendingPathComponent("bonfire-pmset.sudoers")
        try content.write(toFile: tmpPath, atomically: true, encoding: .utf8)

        // Validate, then install with correct ownership/permissions in one admin call
        // so the user only sees one password prompt.
        let install = """
        /usr/sbin/visudo -c -f '\(tmpPath)' && \
        /bin/mv '\(tmpPath)' '\(sudoersPath)' && \
        /usr/sbin/chown root:wheel '\(sudoersPath)' && \
        /bin/chmod 0440 '\(sudoersPath)'
        """
        try runAdmin(install)
    }

    // MARK: - State inspection

    private func currentDisableSleepIsOn() -> Bool {
        let task = Process()
        task.launchPath = pmsetPath
        task.arguments = ["-g", "disablesleep"]
        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = Pipe()
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

    // MARK: - AppleScript admin (only for the one-time sudoers install)

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
