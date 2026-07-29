// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "MeetingNotesCore",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
    ],
    products: [
        .library(name: "MeetingNotesCore", targets: ["MeetingNotesCore"]),
    ],
    dependencies: [
        .package(path: "../../../vendor/traverse-embedder-swift"),
    ],
    targets: [
        .target(
            name: "MeetingNotesCore",
            dependencies: [
                .product(name: "TraverseEmbedder", package: "traverse-embedder-swift"),
            ]
        ),
        .testTarget(
            name: "MeetingNotesCoreTests",
            dependencies: ["MeetingNotesCore"]
        ),
    ]
)
