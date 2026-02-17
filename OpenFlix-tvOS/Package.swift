// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "OpenFlix-tvOS",
    platforms: [
        .tvOS(.v14)
    ],
    products: [
        .library(
            name: "OpenFlix-tvOS",
            targets: ["OpenFlix-tvOS"]),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "OpenFlix-tvOS",
            dependencies: [],
            path: ".",
            exclude: ["Info.plist", "Resources"],
            sources: nil,
            resources: [
                .process("Resources")
            ]
        )
    ]
)
