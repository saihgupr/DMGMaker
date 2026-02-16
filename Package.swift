// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "DMGMaker",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "DMGMaker", targets: ["DMGMaker"])
    ],
    targets: [
        .executableTarget(
            name: "DMGMaker",
            path: "Sources/DMGMaker",
            resources: [
                .process("DefaultBackground.png"),
                .process("applications-folder.png")
            ]
        )
    ]
)
