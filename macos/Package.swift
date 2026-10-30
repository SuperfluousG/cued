// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Cued",
    platforms: [.macOS(.v13)],
    products: [.executable(name: "Cued", targets: ["CuedMac"])],
    targets: [
        // The release bundle receives its one validation resource explicitly.
        // Avoid SwiftPM's generated accessor, which embeds the build machine path.
        .target(name: "CuedCore", exclude: ["Resources"]),
        .executableTarget(name: "CuedMac", dependencies: ["CuedCore"]),
        .testTarget(name: "CuedCoreTests", dependencies: ["CuedCore"])
    ]
)
