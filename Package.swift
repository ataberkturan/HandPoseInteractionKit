// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "HandPoseInteractionKit",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "HandPoseInteractionKit",
            targets: ["HandPoseInteractionKit"]
        )
    ],
    targets: [
        .target(
            name: "HandPoseInteractionKit",
            dependencies: []
        ),
        .testTarget(
            name: "HandPoseInteractionKitTests",
            dependencies: ["HandPoseInteractionKit"]
        )
    ]
)
