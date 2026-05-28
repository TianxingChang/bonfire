import SwiftUI
import AppKit

/// Zero-pixel `NSView` that grabs a reference to its hosting `NSWindow`
/// once it's attached. Used as a `.background` to configure window-level
/// properties that SwiftUI's `Window` scene doesn't expose directly —
/// `collectionBehavior`, window level, etc.
struct WindowAccessor: NSViewRepresentable {
    let configure: (NSWindow) -> Void

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        // `view.window` is nil during makeNSView — it's only populated after
        // the view is added to the window hierarchy. Defer to next runloop tick.
        DispatchQueue.main.async { [weak view] in
            if let window = view?.window {
                configure(window)
            }
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {}
}

extension View {
    /// Sets the hosting window's collection behavior to follow the user
    /// across Spaces. When the window is activated (e.g. via `openWindow`)
    /// it moves to whichever Space is currently active, instead of macOS
    /// switching the user back to where the window was last placed.
    func followsActiveSpace() -> some View {
        background(WindowAccessor { window in
            window.collectionBehavior.insert(.moveToActiveSpace)
        })
    }
}
