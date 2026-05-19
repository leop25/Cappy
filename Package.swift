// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "Cappy",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(
            name: "Cappy",
            path: "Cappy",
            exclude: ["Info.plist"],
            resources: [
                .process("Resources/Assets.xcassets"),
                .copy("Resources/CappyIcon.icns")
            ]
        )
    ]
)
