import SwiftUI

struct BurningLayout: View {
    @ObservedObject var controller: BonfireController
    @State private var now: Date = Date()
    @State private var showInfo = false
    private let ticker = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            header

            if showInfo {
                infoPanel.transition(.opacity)
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
                Text("Awake for \(BurningLayout.formatElapsed(controller.state.runningTime(now: now) ?? 0))")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Button(role: .destructive) {
                controller.stop(reason: .userRequested)
            } label: {
                Label("Stop", systemImage: "stop.fill")
                    .frame(maxWidth: .infinity)
            }
            .controlSize(.large)
            .buttonStyle(.borderedProminent)
        }
        .padding(16)
        .frame(width: 360)
        .onReceive(ticker) { now = $0 }
        .animation(.easeInOut(duration: 0.15), value: showInfo)
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: 8) {
            Image(systemName: "flame.fill").foregroundStyle(.orange)
            Text("Bonfire").font(.headline)
            Text("Keeping your Mac awake")
                .font(.subheadline)
                .foregroundStyle(.orange)
            Spacer()
            Button {
                showInfo.toggle()
            } label: {
                Image(systemName: showInfo ? "info.circle.fill" : "info.circle")
                    .foregroundStyle(.secondary)
                    .imageScale(.large)
            }
            .buttonStyle(.borderless)
        }
    }

    private var infoPanel: some View {
        VStack(alignment: .leading, spacing: 6) {
            bullet("Your Mac stays awake even if you don’t touch it.")
            bullet("Closing the lid keeps it running too, **but only when plugged in**.")
            bullet("On battery, this turns off automatically when battery drops below your threshold.")
        }
        .font(.callout)
        .foregroundStyle(.secondary)
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(NSColor.controlBackgroundColor).opacity(0.4))
        .cornerRadius(8)
    }

    private func bullet(_ markdown: String) -> some View {
        HStack(alignment: .top, spacing: 6) {
            Text("•").foregroundStyle(.secondary)
            Text(.init(markdown))
        }
    }

    // MARK: - Pure helpers

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
