import AppKit

/// Provides the menu bar icons.
///
/// Primary path: load `idle.png` / `burning.png` from the app bundle (colored 3D assets).
/// Fallback: programmatic `NSBezierPath` icons (template / monochrome) if the bundled
/// resources are unavailable — keeps the menu bar non-blank even in degraded builds.
enum IconRenderer {
    /// Rendered size in points. 22pt fills the menu bar more visibly than the
    /// 18pt SF Symbols default — good for our colored 3D campfire icons.
    static let size = NSSize(width: 22, height: 22)

    static func idleImage() -> NSImage {
        loadBundled("idle") ?? fallbackIdleImage()
    }

    static func burningImage() -> NSImage {
        loadBundled("burning") ?? fallbackBurningImage()
    }

    // MARK: - Bundle loading

    private static func loadBundled(_ name: String) -> NSImage? {
        guard let image = NSImage(named: name) else { return nil }
        image.size = size
        image.isTemplate = false   // keep original color (orange flame, brown logs)
        return image
    }

    // MARK: - Fallback (programmatic, template-style)

    private static func fallbackIdleImage() -> NSImage {
        let img = NSImage(size: size, flipped: false) { rect in
            drawLogs(in: rect)
            return true
        }
        img.isTemplate = true
        return img
    }

    private static func fallbackBurningImage() -> NSImage {
        let img = NSImage(size: size, flipped: false) { rect in
            drawLogs(in: rect)
            drawFlame(in: rect)
            return true
        }
        img.isTemplate = true
        return img
    }

    private static func drawLogs(in rect: NSRect) {
        let path = NSBezierPath()
        path.lineWidth = 1.6
        path.lineCapStyle = .round

        path.move(to: NSPoint(x: rect.minX + 2, y: rect.minY + 4))
        path.line(to: NSPoint(x: rect.maxX - 2, y: rect.minY + 10))
        path.move(to: NSPoint(x: rect.maxX - 2, y: rect.minY + 4))
        path.line(to: NSPoint(x: rect.minX + 2, y: rect.minY + 10))

        NSColor.black.setStroke()
        path.stroke()
    }

    private static func drawFlame(in rect: NSRect) {
        let cx = rect.midX
        let baseY = rect.minY + 10
        let topY = rect.maxY - 1
        let flame = NSBezierPath()
        flame.move(to: NSPoint(x: cx, y: baseY))
        flame.curve(
            to: NSPoint(x: cx, y: topY),
            controlPoint1: NSPoint(x: cx - 4, y: baseY + 3),
            controlPoint2: NSPoint(x: cx - 2, y: topY - 1)
        )
        flame.curve(
            to: NSPoint(x: cx, y: baseY),
            controlPoint1: NSPoint(x: cx + 2, y: topY - 1),
            controlPoint2: NSPoint(x: cx + 4, y: baseY + 3)
        )
        flame.close()
        NSColor.black.setFill()
        flame.fill()
    }
}
