// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "TraverseCore",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
    ],
    products: [
        .library(name: "TraverseCore", targets: ["TraverseCore"]),
    ],
    targets: [
        .target(name: "TraverseCore"),
        .testTarget(
            name: "TraverseCoreTests",
            dependencies: ["TraverseCore"]
        ),
    ]
)
