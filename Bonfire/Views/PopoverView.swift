import SwiftUI

struct PopoverView: View {
    @ObservedObject var controller: BonfireController
    @ObservedObject var preferences: Preferences
    var openPreferences: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            if controller.state.isBurning {
                BurningLayout(controller: controller)
            } else {
                IdleLayout(controller: controller)
            }
            HStack {
                Button("Preferences…") { openPreferences() }
                    .buttonStyle(.borderless)
                Spacer()
                Button("Quit Bonfire") { NSApp.terminate(nil) }
                    .buttonStyle(.borderless)
            }
            .font(.footnote)
            .padding(.horizontal, 16)
            .padding(.bottom, 12)
        }
    }
}
