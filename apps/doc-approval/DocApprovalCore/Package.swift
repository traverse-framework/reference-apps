// swift-tools-version: 6.0
import PackageDescription

// TRAVERSE_REPO defaults to /tmp/Traverse in CI (mirrors sync_swift_doc_approval_bundle.sh).
// For a published release, replace the path dependency with:
//   .package(url: "https://github.com/traverse-framework/Traverse", exact: "0.8.2")
// and reference .product(name: "TraverseEmbedder", package: "Traverse") once
// the root Package.swift exports TraverseEmbedder.
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
        .package(path: "/tmp/Traverse/packages/swift/TraverseEmbedder"),
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
