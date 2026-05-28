import SwiftUI

struct PreferencesView: View {
    @ObservedObject var preferences: Preferences

    var body: some View {
        Form {
            Section("Behavior") {
                Toggle("Start at login", isOn: $preferences.launchAtLogin)
                    .onChange(of: preferences.launchAtLogin) { newValue in
                        LaunchAtLogin.setEnabled(newValue)
                    }
                Toggle("Notify when timer ends", isOn: $preferences.notifyOnEnd)
            }
            Section("Battery") {
                Picker("Low battery threshold",
                       selection: $preferences.lowBatteryThreshold) {
                    ForEach(Preferences.allowedThresholds, id: \.self) { v in
                        Text("\(v)%").tag(v)
                    }
                }
                VStack(alignment: .leading, spacing: 4) {
                    Toggle("Keep awake on battery with lid closed", isOn: $preferences.batteryBypassEnabled)
                    (Text("Advanced — overrides macOS sleep policy. ")
                     + Text("Asks for admin password once").bold()
                     + Text(" (the first time you use it) to install a passwordless permission. After that no more prompts. Battery may drain faster than normal."))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                    Text("To revoke: `sudo rm /etc/sudoers.d/bonfire-pmset`")
                        .font(.caption2.monospaced())
                        .foregroundStyle(.tertiary)
                        .padding(.top, 2)
                }
            }
            Section("About") {
                Text("Bonfire")
                    .font(.headline)
                Text("Version \(Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "?")")
                    .foregroundStyle(.secondary)
                    .font(.subheadline)
            }
        }
        .formStyle(.grouped)
        .frame(width: 460, height: 420)
    }
}
