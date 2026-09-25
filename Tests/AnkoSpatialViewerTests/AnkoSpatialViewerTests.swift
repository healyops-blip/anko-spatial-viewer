import XCTest
@testable import AnkoSpatialViewer

final class AnkoSpatialViewerTests: XCTestCase {
    func testSupportedMapSceneSchemaVersion() {
        XCTAssertEqual(AnkoSpatialViewer.mapSceneSchemaVersion, "1.0")
    }
}
