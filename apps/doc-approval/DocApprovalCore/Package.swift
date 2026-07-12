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
    targets: [
        .target(name: "DocApprovalCore"),
        .testTarget(
            name: "DocApprovalCoreTests",
            dependencies: ["DocApprovalCore"]
        ),
    ]
)
