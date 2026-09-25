import Foundation

public enum AnkoSpatialViewer {
    public static let mapSceneSchemaVersion = "1.0"

    public static func decodeScene(from data: Data) throws -> MapScene {
        let scene = try JSONDecoder().decode(MapScene.self, from: data)
        try scene.validate()
        return scene
    }
}

public struct MapScene: Decodable, Equatable, Sendable {
    public let schemaVersion: String
    public let mapId: String
    public let unit: String
    public let rooms: [MapSceneRoom]

    fileprivate func validate() throws {
        guard schemaVersion == AnkoSpatialViewer.mapSceneSchemaVersion else {
            throw MapSceneError.unsupportedSchemaVersion(schemaVersion)
        }
        guard unit == "meter" else {
            throw MapSceneError.unsupportedUnit(unit)
        }
        guard !rooms.isEmpty else {
            throw MapSceneError.emptyScene
        }
        if let invalidRoom = rooms.first(where: { $0.floorPolygon.count < 3 }) {
            throw MapSceneError.invalidRoom(invalidRoom.id)
        }
    }
}

public struct MapSceneRoom: Decodable, Equatable, Sendable {
    public let id: String
    public let name: String
    public let floorPolygon: [MapScenePoint]
    public let privacyEnabled: Bool
}

public struct MapScenePoint: Decodable, Equatable, Sendable {
    public let x: Float
    public let z: Float
}

public enum MapSceneError: Error, Equatable {
    case unsupportedSchemaVersion(String)
    case unsupportedUnit(String)
    case emptyScene
    case invalidRoom(String)
}

extension MapSceneError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case let .unsupportedSchemaVersion(version):
            return "Unsupported MapScene schema version: \(version)"
        case let .unsupportedUnit(unit):
            return "Unsupported MapScene unit: \(unit)"
        case .emptyScene:
            return "MapScene must contain at least one room."
        case let .invalidRoom(roomId):
            return "Room \(roomId) must contain at least three floor points."
        }
    }
}
