# Anko Spatial Viewer

`AnkoSpatialViewer` is the native iOS renderer for Anko `MapScene` data. It is
distributed as a Swift Package and integrated into the Flutter iOS application
through a thin platform bridge.

The package owns native 3D presentation and interaction. It does not own SLAM,
capture, reconstruction, map publication, or Flutter business state.

## Current status

The package decodes versioned `MapScene` JSON and renders its rooms and walls
with RealityKit. Room names are placed directly on the 3D floor. Rooms marked
as `unmonitored` receive a translucent fog layer, while cameras are rendered
with online/offline state and a translucent coverage area. The native view
provides orbit and pinch-to-zoom gestures. The Flutter application supplies
scene data through its iOS Platform View bridge.

## Requirements

- iOS 15 or later
- Swift 5.9 or later

## Development

```sh
swift test
```
