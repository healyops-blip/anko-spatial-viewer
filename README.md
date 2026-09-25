# Anko Spatial Viewer

`AnkoSpatialViewer` is the native iOS renderer for Anko `MapScene` data. It is
distributed as a Swift Package and integrated into the Flutter iOS application
through a thin platform bridge.

The package owns native 3D presentation and interaction. It does not own SLAM,
capture, reconstruction, map publication, or Flutter business state.

## Current status

Version `0.1.0` establishes the package boundary and `MapScene` schema version.
RealityKit rendering and the Flutter Platform View bridge will be added behind
this stable module boundary.

## Requirements

- iOS 15 or later
- Swift 5.9 or later

## Development

```sh
swift test
```
