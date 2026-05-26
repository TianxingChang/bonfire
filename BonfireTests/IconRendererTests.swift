import XCTest
import AppKit
@testable import Bonfire

final class IconRendererTests: XCTestCase {
    func test_idleIcon_isTemplateAndCorrectSize() {
        let img = IconRenderer.idleImage()
        XCTAssertTrue(img.isTemplate)
        XCTAssertEqual(img.size, NSSize(width: 18, height: 18))
    }

    func test_burningIcon_isTemplateAndCorrectSize() {
        let img = IconRenderer.burningImage()
        XCTAssertTrue(img.isTemplate)
        XCTAssertEqual(img.size, NSSize(width: 18, height: 18))
    }

    func test_burningIcon_isVisuallyDifferentFromIdle() {
        let a = IconRenderer.idleImage().tiffRepresentation
        let b = IconRenderer.burningImage().tiffRepresentation
        XCTAssertNotNil(a)
        XCTAssertNotNil(b)
        XCTAssertNotEqual(a, b)
    }
}
