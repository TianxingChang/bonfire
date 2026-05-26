import SwiftUI

struct IdleLayout: View {
    @ObservedObject var controller: BonfireController
    @State private var customH: Int = 1
    @State private var customM: Int = 0
    @State private var untilHour: Int = 23
    @State private var untilMinute: Int = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "flame")
                Text("Bonfire — Idle").font(.headline)
            }

            quickPresets
            Divider()
            customRow
            Divider()
            untilRow
            Divider()
            foreverButton
        }
        .padding(16)
        .frame(width: 280)
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
        HStack {
            Stepper(value: $customH, in: 0...24) { Text("\(customH)h") }.frame(width: 100)
            Stepper(value: $customM, in: 0...59, step: 5) { Text("\(customM)m") }.frame(width: 100)
            Button("Start") {
                try? controller.start(mode: .duration(IdleLayout.customDuration(hours: customH, minutes: customM)))
            }
        }
    }

    private var untilRow: some View {
        HStack {
            Text("Until")
            Stepper(value: $untilHour, in: 0...23) { Text(String(format: "%02d", untilHour)) }.frame(width: 80)
            Text(":")
            Stepper(value: $untilMinute, in: 0...59, step: 5) { Text(String(format: "%02d", untilMinute)) }.frame(width: 80)
            Button("Start") {
                let secs = DurationCalculator.durationUntil(hour: untilHour, minute: untilMinute, now: Date())
                try? controller.start(mode: .duration(secs))
            }
        }
    }

    private var foreverButton: some View {
        Button {
            try? controller.start(mode: .forever)
        } label: {
            Label("Keep Burning", systemImage: "infinity")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.bordered)
    }

    static func customDuration(hours: Int, minutes: Int) -> TimeInterval {
        DurationCalculator.clamped(TimeInterval(hours * 3600 + minutes * 60))
    }
}
