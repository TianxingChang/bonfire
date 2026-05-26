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
        .frame(width: 380, height: 320)
    }
}
