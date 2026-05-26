import SwiftUI

struct BurningLayout: View {
    @ObservedObject var controller: BonfireController
    @State private var now: Date = Date()
    private let ticker = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                Image(systemName: "flame.fill")
                    .foregroundStyle(.orange)
                Text("Bonfire").font(.headline)
                Text("Burning")
                    .font(.subheadline)
                    .foregroundStyle(.orange)
                Spacer()
            }

            VStack(alignment: .leading, spacing: 4) {
                if let remaining = controller.state.timeLeft(now: now) {
                    Text(BurningLayout.formatRemaining(remaining))
                        .font(.system(size: 28, weight: .semibold, design: .rounded))
                        .monospacedDigit()
                } else {
                    Text("No timer")
                        .font(.system(size: 28, weight: .semibold, design: .rounded))
                }
                Text("Running for \(BurningLayout.formatElapsed(controller.state.runningTime(now: now) ?? 0))")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Button(role: .destructive) {
                controller.stop(reason: .userRequested)
            } label: {
                Label("Extinguish", systemImage: "stop.fill")
                    .frame(maxWidth: .infinity)
            }
            .controlSize(.large)
            .buttonStyle(.borderedProminent)
        }
        .padding(16)
        .frame(width: 340)
        .onReceive(ticker) { now = $0 }
    }

    static func formatElapsed(_ seconds: TimeInterval) -> String {
        let total = Int(seconds)
        let h = total / 3600
        let m = (total % 3600) / 60
        return h > 0 ? "\(h)h \(m)m" : "\(m)m"
    }

    static func formatRemaining(_ seconds: TimeInterval?) -> String {
        guard let seconds else { return "no timer" }
        let total = Int(seconds.rounded())
        let h = total / 3600
        let m = (total % 3600) / 60
        return h > 0 ? "\(h)h \(m)m left" : "\(m)m left"
    }
}
