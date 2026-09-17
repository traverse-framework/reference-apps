// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "TraverseEmbedder",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [.library(name: "TraverseEmbedder", targets: ["TraverseEmbedder"])],
    dependencies: [],
    targets: [
        .binaryTarget(
            name: "TraverseSwiftHost",
            url: "https://github.com/traverse-framework/traverse/releases/download/v0.8.2/TraverseSwiftHost.xcframework.zip",
            checksum: "cf9c0461ef777cafb7bedb73f7402dba27f4d956b43dc8157ce56e1006071e48"
        ),
        .target(
            name: "TraverseEmbedder",
            dependencies: [
                "TraverseSwiftHost",
            ]
        ),
        .testTarget(
            name: "TraverseEmbedderTests",
            dependencies: [
                "TraverseEmbedder",
            ]
        ),
    ]
)
