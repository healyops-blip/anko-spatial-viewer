import XCTest
@testable import AnkoSpatialViewer

final class AnkoSpatialViewerTests: XCTestCase {
    func testSupportedMapSceneSchemaVersion() {
        XCTAssertEqual(AnkoSpatialViewer.mapSceneSchemaVersion, "1.0")
    }

    func testDecodesAValidScene() throws {
        let scene = try AnkoSpatialViewer.decodeScene(from: validSceneData)

        XCTAssertEqual(scene.mapId, "home-1")
        XCTAssertEqual(scene.rooms.first?.name, "Living room")
        XCTAssertEqual(scene.rooms.first?.floorPolygon.count, 4)
    }

    func testRejectsAnUnsupportedUnit() {
        let data = validSceneData.replacingOccurrences(
            of: "\"meter\"",
            with: "\"foot\""
        )

        XCTAssertThrowsError(try AnkoSpatialViewer.decodeScene(from: data)) { error in
            XCTAssertEqual(error as? MapSceneError, .unsupportedUnit("foot"))
        }
    }

    private var validSceneData: Data {
        Data(
            """
            {
              "schemaVersion": "1.0",
              "mapId": "home-1",
              "unit": "meter",
              "rooms": [{
                "id": "living",
                "name": "Living room",
                "privacyEnabled": false,
                "floorPolygon": [
                  {"x": 0, "z": 0},
                  {"x": 4, "z": 0},
                  {"x": 4, "z": 3},
                  {"x": 0, "z": 3}
                ]
              }]
            }
            """.utf8
        )
    }
}

private extension Data {
    func replacingOccurrences(of target: String, with replacement: String) -> Data {
        let source = String(decoding: self, as: UTF8.self)
        return Data(source.replacingOccurrences(of: target, with: replacement).utf8)
    }
}
