#if canImport(RealityKit) && canImport(UIKit)
import RealityKit
import UIKit

public final class SpatialViewerView: UIView {
    private let camera = PerspectiveCamera()
    private let focus: SIMD3<Float>
    private let sceneView: ARView
    private var cameraDistance: Float
    private var cameraPitch: Float = 0.78
    private var cameraYaw: Float = 0.72

    public convenience init(frame: CGRect = .zero, sceneData: Data) throws {
        let scene = try AnkoSpatialViewer.decodeScene(from: sceneData)
        self.init(frame: frame, scene: scene)
    }

    public init(frame: CGRect = .zero, scene: MapScene) {
        let metrics = SceneMetrics(scene: scene)
        focus = metrics.focus
        cameraDistance = metrics.cameraDistance
        sceneView = ARView(
            frame: frame,
            cameraMode: .nonAR,
            automaticallyConfigureSession: false
        )
        super.init(frame: frame)
        configureView()
        installScene(scene, metrics: metrics)
        installGestures()
        updateCamera()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func resetCamera() {
        cameraPitch = 0.78
        cameraYaw = 0.72
        updateCamera()
    }

    private func configureView() {
        sceneView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        sceneView.environment.background = .color(UIColor(red: 0.92, green: 0.95, blue: 0.97, alpha: 1))
        addSubview(sceneView)
    }

    private func installScene(_ scene: MapScene, metrics: SceneMetrics) {
        let anchor = AnchorEntity(world: .zero)
        anchor.addChild(RoomEntityBuilder.makeHome(from: scene, metrics: metrics))
        anchor.addChild(camera)
        anchor.addChild(makeLight())
        sceneView.scene.anchors.append(anchor)
    }

    private func makeLight() -> DirectionalLight {
        let light = DirectionalLight()
        light.light.intensity = 2_800
        light.orientation = simd_quatf(angle: -.pi / 3, axis: [1, 0, 0])
        return light
    }

    private func installGestures() {
        addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(handlePan)))
        addGestureRecognizer(UIPinchGestureRecognizer(target: self, action: #selector(handlePinch)))
    }

    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: self)
        cameraYaw -= Float(translation.x) * 0.008
        cameraPitch = (cameraPitch + Float(translation.y) * 0.005).clamped(to: 0.28...1.30)
        gesture.setTranslation(.zero, in: self)
        updateCamera()
    }

    @objc private func handlePinch(_ gesture: UIPinchGestureRecognizer) {
        cameraDistance = (cameraDistance / Float(gesture.scale)).clamped(to: 4...30)
        gesture.scale = 1
        updateCamera()
    }

    private func updateCamera() {
        let horizontalDistance = cameraDistance * cos(cameraPitch)
        let position = SIMD3<Float>(
            focus.x + horizontalDistance * sin(cameraYaw),
            focus.y + cameraDistance * sin(cameraPitch),
            focus.z + horizontalDistance * cos(cameraYaw)
        )
        camera.look(at: focus, from: position, relativeTo: nil)
    }
}

private struct SceneMetrics {
    let centerX: Float
    let centerZ: Float
    let span: Float

    init(scene: MapScene) {
        let points = scene.rooms.flatMap(\.floorPolygon)
        let minX = points.map(\.x).min() ?? 0
        let maxX = points.map(\.x).max() ?? 1
        let minZ = points.map(\.z).min() ?? 0
        let maxZ = points.map(\.z).max() ?? 1
        centerX = (minX + maxX) / 2
        centerZ = (minZ + maxZ) / 2
        span = max(maxX - minX, maxZ - minZ)
    }

    var focus: SIMD3<Float> { [0, 0.35, 0] }
    var cameraDistance: Float { max(span * 1.25, 7) }

    func centered(_ point: MapScenePoint) -> SIMD3<Float> {
        [point.x - centerX, 0, point.z - centerZ]
    }
}

private enum RoomEntityBuilder {
    private static let wallHeight: Float = 1.35
    private static let wallThickness: Float = 0.08

    static func makeHome(from scene: MapScene, metrics: SceneMetrics) -> Entity {
        let home = Entity()
        for (index, room) in scene.rooms.enumerated() {
            home.addChild(makeFloor(for: room, index: index, metrics: metrics))
            addWalls(for: room, to: home, metrics: metrics)
        }
        return home
    }

    private static func makeFloor(
        for room: MapSceneRoom,
        index: Int,
        metrics: SceneMetrics
    ) -> ModelEntity {
        let bounds = RoomBounds(room: room, metrics: metrics)
        let material = SimpleMaterial(
            color: floorColor(index: index, isPrivate: room.privacyEnabled),
            roughness: 0.82,
            isMetallic: false
        )
        let floor = ModelEntity(
            mesh: .generateBox(size: [bounds.width, 0.06, bounds.depth]),
            materials: [material]
        )
        floor.position = [bounds.centerX, -0.03, bounds.centerZ]
        return floor
    }

    private static func addWalls(
        for room: MapSceneRoom,
        to home: Entity,
        metrics: SceneMetrics
    ) {
        let points = room.floorPolygon.map(metrics.centered)
        for index in points.indices {
            let start = points[index]
            let end = points[(index + 1) % points.count]
            home.addChild(makeWall(from: start, to: end))
        }
    }

    private static func makeWall(
        from start: SIMD3<Float>,
        to end: SIMD3<Float>
    ) -> ModelEntity {
        let delta = end - start
        let length = hypot(delta.x, delta.z)
        let material = SimpleMaterial(
            color: UIColor(white: 0.98, alpha: 1),
            roughness: 0.72,
            isMetallic: false
        )
        let wall = ModelEntity(
            mesh: .generateBox(size: [length, wallHeight, wallThickness]),
            materials: [material]
        )
        wall.position = [(start.x + end.x) / 2, wallHeight / 2, (start.z + end.z) / 2]
        wall.orientation = simd_quatf(angle: -atan2(delta.z, delta.x), axis: [0, 1, 0])
        return wall
    }

    private static func floorColor(index: Int, isPrivate: Bool) -> UIColor {
        if isPrivate {
            return UIColor(red: 0.72, green: 0.76, blue: 0.80, alpha: 1)
        }
        let colors = [
            UIColor(red: 0.84, green: 0.91, blue: 0.96, alpha: 1),
            UIColor(red: 0.93, green: 0.87, blue: 0.76, alpha: 1),
            UIColor(red: 0.82, green: 0.90, blue: 0.84, alpha: 1),
        ]
        return colors[index % colors.count]
    }
}

private struct RoomBounds {
    let centerX: Float
    let centerZ: Float
    let width: Float
    let depth: Float

    init(room: MapSceneRoom, metrics: SceneMetrics) {
        let points = room.floorPolygon.map(metrics.centered)
        let minX = points.map(\.x).min() ?? 0
        let maxX = points.map(\.x).max() ?? 0
        let minZ = points.map(\.z).min() ?? 0
        let maxZ = points.map(\.z).max() ?? 0
        centerX = (minX + maxX) / 2
        centerZ = (minZ + maxZ) / 2
        width = max(maxX - minX, 0.1)
        depth = max(maxZ - minZ, 0.1)
    }
}

private extension Float {
    func clamped(to range: ClosedRange<Float>) -> Float {
        min(max(self, range.lowerBound), range.upperBound)
    }
}
#endif
