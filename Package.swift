// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "GlassNeedle",
    platforms: [.macOS(.v15)],
    products: [.executable(name: "GlassNeedle", targets: ["GlassNeedle"])],
    targets: [
        .executableTarget(
            name: "GlassNeedle",
            path: "Sources/GlassNeedle"
        )
    ],
    swiftLanguageModes: [.v5]
)
