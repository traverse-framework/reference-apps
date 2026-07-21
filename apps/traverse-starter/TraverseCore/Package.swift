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
    dependencies: [
        .package(path: "../../../vendor/traverse-embedder-swift"),
    ],
    targets: [
        .target(
            name: "TraverseCore",
            dependencies: [
                .product(name: "TraverseEmbedder", package: "traverse-embedder-swift"),
            ]
        ),
        .testTarget(
            name: "TraverseCoreTests",
            dependencies: ["TraverseCore"]
        ),
    ]
)
