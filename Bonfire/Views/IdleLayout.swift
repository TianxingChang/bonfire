import SwiftUI

struct IdleLayout: View {
    @ObservedObject var controller: BonfireController
    @State private var customH: Int = 1
    @State private var customM: Int = 0
    @State private var untilHour: Int = 23
    @State private var untilMinute: Int = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Image(systemName: "flame")
                Text("Bonfire").font(.headline)
                Text("Idle")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
            }

            section("Quick start") {
                quickPresets
            }

            section("Custom duration") {
                customRow
            }

            section("Until a time") {
                untilRow
            }

            Divider().padding(.vertical, 2)

            foreverButton
        }
        .padding(16)
        .frame(width: 340)
    }

    private func section<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title.uppercased())
                .font(.caption2)
                .fontWeight(.semibold)
                .tracking(0.5)
                .foregroundStyle(.secondary)
            content()
        }
    }

    private var quickPresets: some View {
        HStack(spacing: 6) {
            preset("30m", seconds: 1800)
            preset("1h",  seconds: 3600)
            preset("2h",  seconds: 7200)
            preset("4h",  seconds: 14400)
        }
    }

    private func preset(_ title: String, seconds: TimeInterval) -> some View {
        Button(title) {
            try? controller.start(mode: .duration(seconds))
        }
        .buttonStyle(.bordered)
        .frame(maxWidth: .infinity)
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

    private var untilRow: some View {
        HStack(spacing: 6) {
            Stepper(value: $untilHour, in: 0...23) {
                Text(String(format: "%02d", untilHour)).monospacedDigit()
            }
            Text(":").foregroundStyle(.secondary).font(.title3)
            Stepper(value: $untilMinute, in: 0...59, step: 5) {
                Text(String(format: "%02d", untilMinute)).monospacedDigit()
            }
            Spacer(minLength: 4)
            Button("Start") {
                let secs = DurationCalculator.durationUntil(hour: untilHour, minute: untilMinute, now: Date())
                try? controller.start(mode: .duration(secs))
            }
            .buttonStyle(.borderedProminent)
        }
    }

    private var foreverButton: some View {
        Button {
            try? controller.start(mode: .forever)
        } label: {
            Label("Keep Burning forever", systemImage: "infinity")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.bordered)
        .controlSize(.large)
    }

    static func customDuration(hours: Int, minutes: Int) -> TimeInterval {
        DurationCalculator.clamped(TimeInterval(hours * 3600 + minutes * 60))
    }
}
