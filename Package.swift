// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Opus",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "OpusApp", targets: ["OpusApp"])
    ],
    targets: [
        .executableTarget(
            name: "OpusApp",
            path: "Sources/OpusApp",
            resources: [
                .process("Shaders")
            ],
            swiftSettings: [
                .define("PLATFORM_MACOS")
            ]
        )
    ]
)
