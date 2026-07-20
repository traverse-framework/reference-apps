// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "DocApprovalCore",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
    ],
    products: [
        .library(name: "DocApprovalCore", targets: ["DocApprovalCore"]),
    ],
    dependencies: [
        .package(path: "../../../vendor/traverse-embedder-swift"),
    ],
    targets: [
        .target(
            name: "DocApprovalCore",
            dependencies: [
                .product(name: "TraverseEmbedder", package: "TraverseEmbedder"),
            ]
        ),
        .testTarget(
            name: "DocApprovalCoreTests",
            dependencies: ["DocApprovalCore"]
        ),
    ]
)
