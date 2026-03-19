// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "DMG Maker",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "DMG Maker", targets: ["DMGMaker"])
    ],
    targets: [
        .executableTarget(
            name: "DMGMaker",
            path: "Sources/DMGMaker",
            exclude: ["Info.plist"],
            resources: [
                .process("AppIcon.icns"),
                .process("DefaultBackground.png"),
                .process("applications-folder.png"),
                .copy("Resources/create-dmg")
            ],
            linkerSettings: [
                .unsafeFlags([
                    "-Xlinker", "-sectcreate",
                    "-Xlinker", "__TEXT",
                    "-Xlinker", "__info_plist",
                    "-Xlinker", "Sources/DMGMaker/Info.plist"
                ])
            ]
        )
    ]
)
