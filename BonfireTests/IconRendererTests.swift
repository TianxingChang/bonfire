import XCTest
import AppKit
@testable import Bonfire

final class IconRendererTests: XCTestCase {
    func test_idleIcon_correctSize() {
        let img = IconRenderer.idleImage()
        XCTAssertEqual(img.size, IconRenderer.size)
    }

    func test_burningIcon_correctSize() {
        let img = IconRenderer.burningImage()
        XCTAssertEqual(img.size, IconRenderer.size)
    }

    func test_burningIcon_isVisuallyDifferentFromIdle() {
        let a = IconRenderer.idleImage().tiffRepresentation
        let b = IconRenderer.burningImage().tiffRepresentation
        XCTAssertNotNil(a)
        XCTAssertNotNil(b)
        XCTAssertNotEqual(a, b)
    }

    /// Confirms the bundled PNGs are reachable from the app bundle.
    /// If this fails, the resources didn't get copied — check `project.yml`
    /// or that `Bonfire/Resources/*.png` is included in the target's sources.
    func test_bundledPNGs_areLoadable() {
        XCTAssertNotNil(NSImage(named: "idle"), "idle.png missing from app bundle")
        XCTAssertNotNil(NSImage(named: "burning"), "burning.png missing from app bundle")
    }

    /// When the bundled PNGs load, the icons should be colored (not template).
    /// When they fall back to programmatic drawing, they'd be template.
    /// We expect the PNGs to be present in tests.
    func test_loadedIcons_areColoredNotTemplate() {
        XCTAssertFalse(IconRenderer.idleImage().isTemplate)
        XCTAssertFalse(IconRenderer.burningImage().isTemplate)
    }
}
