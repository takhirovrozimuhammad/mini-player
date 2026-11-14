// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "GlassNeedle",
    platforms: [.macOS(.v15)],
    products: [.executable(name: "GlassNeedle", targets: ["GlassNeedle"])],
    dependencies: [
        // Existing, tested MIT open-source macOS notch geometry + pointer handling.
        .package(url: "https://github.com/duongductrong/NotchKit.git", branch: "master"),
        // Existing, tested MIT open-source screen notch/safe area metrics.
        .package(url: "https://github.com/bring-shrubbery/dynamic-landing.git", branch: "main"),
    ],
    targets: [
        .executableTarget(
            name: "GlassNeedle",
            dependencies: [
                .product(name: "NotchKit", package: "NotchKit"),
                .product(name: "DynamicLanding", package: "dynamic-landing"),
            ],
            path: "Sources/GlassNeedle"
        )
    ],
    swiftLanguageModes: [.v5]
)
