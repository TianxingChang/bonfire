import SwiftUI

struct BurningLayout: View {
    @ObservedObject var controller: BonfireController
    @State private var now: Date = Date()
    private let ticker = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "flame.fill")
                Text("Bonfire — Burning").font(.headline)
            }
            statusLine
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
        .frame(width: 280)
        .onReceive(ticker) { now = $0 }
    }

    @ViewBuilder private var statusLine: some View {
        let elapsed = controller.state.runningTime(now: now)
        let remaining = controller.state.timeLeft(now: now)
        Text("Running \(BurningLayout.formatElapsed(elapsed ?? 0)) · \(BurningLayout.formatRemaining(remaining))")
            .font(.subheadline)
            .foregroundStyle(.secondary)
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
