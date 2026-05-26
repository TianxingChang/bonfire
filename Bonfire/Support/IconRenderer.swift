import AppKit

enum IconRenderer {
    static let size = NSSize(width: 18, height: 18)

    static func idleImage() -> NSImage {
        let img = NSImage(size: size, flipped: false) { rect in
            drawLogs(in: rect)
            return true
        }
        img.isTemplate = true
        return img
    }

    static func burningImage() -> NSImage {
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
