// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "LoopCore",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
    ],
    products: [
        .library(name: "LoopCore", targets: ["LoopCore"]),
    ],
    dependencies: [
        .package(path: "../../../vendor/traverse-embedder-swift"),
    ],
    targets: [
        .target(
            name: "LoopCore",
            dependencies: [
                .product(name: "TraverseEmbedder", package: "traverse-embedder-swift"),
            ]
        ),
        .testTarget(
            name: "LoopCoreTests",
            dependencies: ["LoopCore"]
        ),
    ]
)
