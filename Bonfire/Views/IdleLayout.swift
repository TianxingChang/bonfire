import SwiftUI

struct IdleLayout: View {
    @ObservedObject var controller: BonfireController
    @State private var customH: Int = 1
    @State private var customM: Int = 0
    @State private var showCustom = false
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            header

            Text("Keep your Mac awake for:")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            durationRow

            if showCustom {
                customRow.transition(.opacity)
            }

            Divider().padding(.vertical, 2)

            keepAwakeForeverButton
        }
        .padding(16)
        .frame(width: 360)
        .animation(.easeInOut(duration: 0.15), value: showCustom)
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: 8) {
            Image(systemName: "flame")
            Text("Bonfire").font(.headline)
            Text("Off")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            Button {
                NSApp.activate(ignoringOtherApps: true)
                openWindow(id: "info")
            } label: {
                Image(systemName: "info.circle")
                    .foregroundStyle(.secondary)
                    .imageScale(.large)
            }
            .buttonStyle(.borderless)
            .help("How Bonfire works")
        }
    }

    // MARK: - Duration buttons

    private var durationRow: some View {
        HStack(spacing: 6) {
            preset("30m", seconds: 1800)
            preset("1h",  seconds: 3600)
            preset("2h",  seconds: 7200)
            preset("4h",  seconds: 14400)
            customToggle
        }
    }

    private func preset(_ title: String, seconds: TimeInterval) -> some View {
        Button(title) {
            try? controller.start(mode: .duration(seconds))
        }
        .buttonStyle(.bordered)
        .frame(maxWidth: .infinity)
    }

    private var customToggle: some View {
        Button {
            showCustom.toggle()
        } label: {
            HStack(spacing: 3) {
                Text("Custom")
                Image(systemName: showCustom ? "chevron.up" : "chevron.down")
                    .font(.caption2)
            }
            .fixedSize()                // size to content, no truncation
        }
        .buttonStyle(.bordered)
    }

    private var customRow: some View {
        HStack(spacing: 10) {
            Stepper(value: $customH, in: 0...24) {
                Text("\(customH) h").monospacedDigit()
            }
            Stepper(value: $customM, in: 0...59, step: 5) {
                Text("\(customM) m").monospacedDigit()
            }
            Spacer(minLength: 4)
            Button("Start") {
                try? controller.start(mode: .duration(IdleLayout.customDuration(hours: customH, minutes: customM)))
            }
            .buttonStyle(.borderedProminent)
        }
    }

    // MARK: - Forever button

    private var keepAwakeForeverButton: some View {
        Button {
            try? controller.start(mode: .forever)
        } label: {
            VStack(spacing: 2) {
                Label("Keep awake — no timer", systemImage: "infinity")
                Text("Your Mac won’t sleep until you turn this off")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.bordered)
        .controlSize(.large)
    }

    // MARK: - Pure helpers

    static func customDuration(hours: Int, minutes: Int) -> TimeInterval {
        DurationCalculator.clamped(TimeInterval(hours * 3600 + minutes * 60))
    }
}
