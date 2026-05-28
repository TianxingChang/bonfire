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
                bulletWithEmphasis(
                    pre: "Closing the lid keeps it running too, ",
                    emphasis: "but only when plugged in",
                    post: ". On battery, closing the lid still puts your Mac to sleep."
                )
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

    /// A bullet with a colored, bold span in the middle.
    /// Uses Text `+` concatenation so the emphasis wraps inline with the
    /// surrounding paragraph instead of breaking layout.
    private func bulletWithEmphasis(pre: String, emphasis: String, post: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Text("•")
                .foregroundStyle(.secondary)
                .frame(width: 8, alignment: .leading)
            (Text(pre)
             + Text(emphasis).foregroundColor(.orange).bold()
             + Text(post))
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
