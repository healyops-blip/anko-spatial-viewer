// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "AnkoSpatialViewer",
    platforms: [
        .iOS(.v15),
    ],
    products: [
        .library(
            name: "AnkoSpatialViewer",
            targets: ["AnkoSpatialViewer"]
        ),
    ],
    targets: [
        .target(name: "AnkoSpatialViewer"),
        .testTarget(
            name: "AnkoSpatialViewerTests",
            dependencies: ["AnkoSpatialViewer"]
        ),
    ]
)
