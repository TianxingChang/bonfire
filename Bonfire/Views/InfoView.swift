import SwiftUI

struct InfoView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(spacing: 10) {
                Image(systemName: "flame.fill")
                    .foregroundStyle(.orange)
                    .imageScale(.large)
                Text("How Bonfire keeps your Mac awake")
                    .font(.title3)
                    .bold()
            }

            VStack(alignment: .leading, spacing: 14) {
                bullet("Your Mac stays awake the whole time, even if you don’t touch it.")
                bullet("The screen may still dim or turn off — that’s fine, your Mac keeps running underneath.")
                bullet("Closing the lid keeps it running too, **but only when plugged in**. On battery, closing the lid still puts your Mac to sleep.")
                bullet("On battery, Bonfire turns itself off when battery drops below your threshold (default 20%, change in Preferences).")
            }

            HStack {
                Spacer()
                Button("Done") {
                    NSApp.keyWindow?.close()
                }
                .keyboardShortcut(.defaultAction)
            }
            .padding(.top, 4)
        }
        .padding(24)
        .frame(width: 480, alignment: .leading)
    }

    private func bullet(_ markdown: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Text("•")
                .foregroundStyle(.secondary)
                .frame(width: 8, alignment: .leading)
            Text(.init(markdown))
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
