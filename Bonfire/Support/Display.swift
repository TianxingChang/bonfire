import Foundation

enum Display {
    /// Puts all attached displays to sleep immediately. Equivalent to
    /// `/usr/bin/pmset displaysleepnow`. **Doesn't require sudo** —
    /// regular user permissions are enough for display sleep (only
    /// system sleep override needs root).
    ///
    /// Displays wake again on mouse / keyboard / lid open. The system
    /// itself keeps running — useful for "click Keep Burning → click
    /// Turn off display → close the lid and walk away" flow.
    static func sleepNow() {
        let task = Process()
        task.launchPath = "/usr/bin/pmset"
        task.arguments = ["displaysleepnow"]
        task.standardOutput = Pipe()
        task.standardError = Pipe()
        do {
            try task.run()
            task.waitUntilExit()
        } catch {
            NSLog("Bonfire: Display.sleepNow failed: \(error)")
        }
    }
}
