import SwiftUI

@main
struct BonfireApp: App {
    var body: some Scene {
        MenuBarExtra("Bonfire", systemImage: "flame") {
            Text("Hello, Bonfire")
                .padding()
        }
        .menuBarExtraStyle(.window)
    }
}
