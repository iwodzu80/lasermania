// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Lasermania",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .library(name: "LasermaniaCore", targets: ["LasermaniaCore"]),
        .executable(name: "Lasermania", targets: ["LasermaniaApp"])
    ],
    targets: [
        .target(
            name: "LasermaniaCore",
            resources: [
                .copy("Resources/Levels")
            ]
        ),
        .executableTarget(
            name: "LasermaniaApp",
            dependencies: [
                "LasermaniaCore"
            ],
            resources: [
                .copy("Resources/Audio"),
                .copy("Resources/Sprites")
            ]
        ),
        .testTarget(
            name: "LasermaniaCoreTests",
            dependencies: [
                "LasermaniaCore"
            ]
        )
    ]
)
