// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "OpenFlix-iOS",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "OpenFlix-iOS",
            targets: ["OpenFlix-iOS"]
        )
    ],
    dependencies: [],
    targets: [
        .target(
            name: "OpenFlix-iOS",
            dependencies: [],
            path: "OpenFlix-iOS",
            resources: [
                .process("Resources")
            ]
        )
    ]
)
